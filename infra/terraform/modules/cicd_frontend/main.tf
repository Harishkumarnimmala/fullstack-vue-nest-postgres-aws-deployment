# CodeBuild role
resource "aws_iam_role" "codebuild" {
  name = "${var.project}-cb-frontend-role-${var.environment}"
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
    actions = ["s3:GetObject","s3:PutObject","s3:DeleteObject","s3:ListBucket","s3:GetBucketLocation"]
    resources = [
      "arn:aws:s3:::${var.frontend_bucket_name}",
      "arn:aws:s3:::${var.frontend_bucket_name}/*",
      "arn:aws:s3:::${var.artifacts_bucket}",
      "arn:aws:s3:::${var.artifacts_bucket}/*"
    ]
  }
  statement {
    actions   = ["cloudfront:CreateInvalidation","cloudfront:GetDistribution","cloudfront:GetInvalidation","cloudfront:ListDistributions"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cb_inline" {
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.cb_inline.json
}

# CodePipeline role
resource "aws_iam_role" "codepipeline" {
  name = "${var.project}-cp-frontend-role-${var.environment}"
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

resource "aws_codebuild_project" "frontend" {
  name         = "${var.project}-${var.environment}-frontend-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts { type = "CODEPIPELINE" }

  environment {
  compute_type    = "BUILD_GENERAL1_SMALL"
  image           = "aws/codebuild/standard:7.0"
  type            = "LINUX_CONTAINER"
  privileged_mode = false

  environment_variable {
    name  = "AWS_REGION"
    value = var.region
  }
  environment_variable {
    name  = "BUCKET"
    value = var.frontend_bucket_name
  }
  environment_variable {
    name  = "DISTRIBUTION_ID"
    value = var.distribution_id
  }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-YAML
      version: 0.2
      phases:
        install:
          commands:
            - node --version || true
            - npm --version || true
        build:
          commands:
            - cd frontend
            - npm ci
            - npm run build
        post_build:
          commands:
            - echo "Uploading to S3 bucket $BUCKET"
            - aws s3 sync dist s3://$BUCKET --delete
            - echo "Invalidating CloudFront"
            - aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'
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

resource "aws_codepipeline" "frontend" {
  name     = "${var.project}-${var.environment}-frontend-pipeline"
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
      name            = "BuildAndDeployFrontend"
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

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
