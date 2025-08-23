# CodeBuild: build Vue app, upload to S3, invalidate CloudFront
resource "aws_codebuild_project" "frontend" {
  name         = "${var.project}-cb-frontend"
  description  = "Builds Vue frontend, syncs to S3, invalidates CloudFront"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "FRONTEND_BUCKET"
      value = var.frontend_bucket
    }
    environment_variable {
      name  = "DISTRIBUTION_ID"
      value = var.cloudfront_distribution_id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-YAML
      version: 0.2
      phases:
        install:
          commands:
            - cp frontend/.env.production.serverless frontend/.env.production || true
            - cd frontend
            - node -v
            - npm ci
        build:
          commands:
            - npm run build
        post_build:
          commands:
            - cd ..
            - aws s3 sync frontend/dist s3://$FRONTEND_BUCKET/ --delete
            - aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
      artifacts:
        files:
          - '**/*'
        discard-paths: yes
    YAML
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/codebuild/${var.project}-cb-frontend"
    }
  }

  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "cicd"
    Component = "codebuild-frontend"
  })
}

# CodePipeline: GitHub (via CodeStar) -> CodeBuild
resource "aws_codepipeline" "frontend" {
  name     = "${var.project}-cp-frontend"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    type     = "S3"
    location = var.artifacts_bucket
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
        DetectChanges    = "true"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build_Frontend"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.frontend.name
      }
    }
  }

  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "cicd"
    Component = "codepipeline-frontend"
  })
}
