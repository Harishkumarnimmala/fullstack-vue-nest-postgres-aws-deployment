# CodeBuild role
resource "aws_iam_role" "codebuild" {
  name = "${var.project}-cb-backend-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect="Allow", Principal={ Service="codebuild.amazonaws.com" }, Action="sts:AssumeRole" }]
  })
}

data "aws_iam_policy_document" "cb_inline" {
  statement {
    actions   = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
    resources = ["*"]
  }
  statement {
    actions   = ["s3:GetObject","s3:PutObject","s3:GetObjectVersion","s3:GetBucketAcl","s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.artifacts_bucket}", "arn:aws:s3:::${var.artifacts_bucket}/*"]
  }
  statement {
    actions   = ["ecr:GetAuthorizationToken","ecr:BatchCheckLayerAvailability","ecr:CompleteLayerUpload","ecr:GetDownloadUrlForLayer","ecr:InitiateLayerUpload","ecr:PutImage","ecr:UploadLayerPart","ecr:BatchGetImage"]
    resources = ["*"]
  }
  statement {
    actions   = ["ecs:UpdateService","ecs:DescribeServices","ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cb_inline" {
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.cb_inline.json
}

# CodePipeline role
resource "aws_iam_role" "codepipeline" {
  name = "${var.project}-cp-backend-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect="Allow", Principal={ Service="codepipeline.amazonaws.com" }, Action="sts:AssumeRole" }]
  })
}

data "aws_iam_policy_document" "cp_inline" {
  statement {
    actions   = ["s3:GetObject","s3:PutObject","s3:GetBucketVersioning","s3:GetObjectVersion","s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.artifacts_bucket}", "arn:aws:s3:::${var.artifacts_bucket}/*"]
  }
  statement {
    actions   = ["codebuild:StartBuild","codebuild:BatchGetBuilds"]
    resources = ["*"]
  }
  statement {
    actions   = ["codestar-connections:UseConnection"]
    resources = [var.connection_arn]
  }
}

resource "aws_iam_role_policy" "cp_inline" {
  role   = aws_iam_role.codepipeline.name
  policy = data.aws_iam_policy_document.cp_inline.json
}

resource "aws_codebuild_project" "backend" {
  name         = "${var.project}-${var.environment}-backend-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
  compute_type    = "BUILD_GENERAL1_SMALL"
  image           = "aws/codebuild/standard:7.0"
  type            = "LINUX_CONTAINER"
  privileged_mode = true

  environment_variable {
    name  = "AWS_REGION"
    value = var.region
  }
  environment_variable {
    name  = "ACCOUNT_ID"
    value = var.account_id
  }
  environment_variable {
    name  = "ECR_REPO"
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
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
            - COMMIT_SHA=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c1-7)
            - IMAGE_TAG=$${COMMIT_SHA:-latest}
        build:
          commands:
            - echo Building Docker image...
            - cd backend
            - docker build -t $ECR_REPO:$IMAGE_TAG -t $ECR_REPO:latest .
        post_build:
          commands:
            - echo Pushing images to ECR...
            - docker push $ECR_REPO:$IMAGE_TAG
            - docker push $ECR_REPO:latest
            - echo Forcing ECS deployment...
            - aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --force-new-deployment --region $AWS_REGION
      artifacts:
        files:
          - '**/*'
    YAML
  }

  logs_config {
    cloudwatch_logs {
      group_name = var.log_group_name
    }
  }
}

resource "aws_codepipeline" "backend" {
  name     = "${var.project}-${var.environment}-backend-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.artifacts_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = var.connection_arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "BuildAndDeploy"
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

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
