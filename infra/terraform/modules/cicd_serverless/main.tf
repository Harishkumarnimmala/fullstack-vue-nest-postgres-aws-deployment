#####################################
# CodeBuild project + CodePipeline
#####################################

# Uses IAM roles from iam.tf in the same module:
#   - aws_iam_role.codebuild
#   - aws_iam_role.codepipeline

resource "aws_codebuild_project" "serverless" {
  name         = "${var.project}-sls-build"
  description  = "Build + zip serverless lambda and update function code"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = var.lambda_function_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-YAML
      version: 0.2
      phases:
        pre_build:
          commands:
            - 'echo "entering serverless/"'
            - 'cd serverless'
            - 'echo "installing deps"'
            - 'npm ci || npm install'
        build:
          commands:
            - 'echo "zipping lambda code"'
            - 'zip -qr ../lambda.zip .'
            - 'echo "updating function: $LAMBDA_FUNCTION_NAME"'
            - 'aws lambda update-function-code --function-name "$LAMBDA_FUNCTION_NAME" --zip-file fileb://../lambda.zip'
        post_build:
          commands:
            - 'echo "done"'
    YAML
  }


  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.project}-sls-build"
      stream_name = "build"
    }
  }

  tags = var.tags
}

resource "aws_codepipeline" "serverless" {
  name     = "${var.project}-sls-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.artifacts_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]
      configuration = {
        ConnectionArn        = var.github_connection_arn
        FullRepositoryId     = "${var.repo_owner}/${var.repo_name}"
        BranchName           = var.repo_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "UpdateLambda"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.serverless.name
      }
    }
  }

  tags = var.tags
}
