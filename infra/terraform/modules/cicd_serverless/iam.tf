#####################################
# IAM for CodeBuild + CodePipeline
#####################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  artifacts_bucket_arn   = "arn:aws:s3:::${var.artifacts_bucket}"
  artifacts_objects_arn  = "arn:aws:s3:::${var.artifacts_bucket}/*"
}

# -------------------------------
# CodeBuild service role
# -------------------------------
data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.project}-sls-cb-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
  tags               = var.tags
}

# Inline policy: logs, S3 artifacts, Lambda update-function-code
resource "aws_iam_role_policy" "codebuild_inline" {
  name = "${var.project}-sls-cb-policy"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # CloudWatch Logs
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "*"
      },
      # S3 artifacts
      {
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource: [
          local.artifacts_bucket_arn,
          local.artifacts_objects_arn
        ]
      },
      # Update Lambda code
      {
        Effect: "Allow",
        Action: [
          "lambda:UpdateFunctionCode",
          "lambda:PublishVersion",
          "lambda:UpdateFunctionConfiguration",
          "lambda:GetFunction"
        ],
        Resource: [
          "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_function_name}"
        ]
      }
    ]
  })
}

# -------------------------------
# CodePipeline service role
# -------------------------------
data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.project}-sls-cp-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
  tags               = var.tags
}

# Inline policy: S3 artifacts, start CodeBuild, use CodeStar connection
resource "aws_iam_role_policy" "codepipeline_inline" {
  name = "${var.project}-sls-cp-policy"
  role = aws_iam_role.codepipeline.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # S3 artifact store
      {
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ],
        Resource: [
          local.artifacts_bucket_arn,
          local.artifacts_objects_arn
        ]
      },
      # Start CodeBuild
      {
        Effect: "Allow",
        Action: [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ],
        Resource: "*"
      },
      # Use GitHub CodeStar connection
      {
        Effect: "Allow",
        Action: ["codestar-connections:UseConnection"],
        Resource: var.github_connection_arn
      }
    ]
  })
}

# Outputs (used by main.tf)
output "codebuild_role_arn" {
  value = aws_iam_role.codebuild.arn
}

output "codepipeline_role_arn" {
  value = aws_iam_role.codepipeline.arn
}
