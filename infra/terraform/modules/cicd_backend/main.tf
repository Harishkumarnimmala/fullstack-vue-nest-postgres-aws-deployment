data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

###### CodeBuild project (build+push image, ECS deploy)

resource "aws_codebuild_project" "backend" {
  name         = "${var.project}-cb-backend"
  description  = "Builds Docker image for backend, pushes to ECR, forces ECS deploy"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.compute_type
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    privileged_mode             = var.privileged_mode
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.name
    }
    environment_variable {
      name  = "ECR_REPO_URL"
      value = var.ecr_repo_url
    }
    environment_variable {
      name  = "ECS_CLUSTER"
      value = var.ecs_cluster_name
    }
    environment_variable {
      name  = "ECS_SERVICE"
      value = var.ecs_service_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-YAML
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws --version
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${var.ecr_repo_url}
            - COMMIT_SHA=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c1-7)
            - IMAGE_TAG=${COMMIT_SHA:-latest}
            - echo "Using IMAGE_TAG=$IMAGE_TAG"
        build:
          commands:
            - echo Building the Docker image...
            - docker build -t ${var.ecr_repo_url}:$IMAGE_TAG -f backend/Dockerfile backend
        post_build:
          commands:
            - echo Pushing the Docker image...
            - docker push ${var.ecr_repo_url}:$IMAGE_TAG
            - echo Forcing new ECS deployment...
            - aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment --region $AWS_REGION
      artifacts:
        files:
          - '**/*'
        discard-paths: yes
    YAML
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/codebuild/${var.project}-cb-backend"
    }
  }

  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "cicd"
    Component = "codebuild-backend"
  })
}


####### CodePipeline (Source -> Build)

resource "aws_codepipeline" "backend" {
  name     = "${var.project}-cp-backend"
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
      name            = "Build_Backend"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "cicd"
    Component = "codepipeline-backend"
  })
}
