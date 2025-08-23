data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  artifacts_bucket_arn = "arn:aws:s3:::${var.artifacts_bucket}"
  artifacts_objects_arn = "arn:aws:s3:::${var.artifacts_bucket}/*"
}

# --- CodeBuild service role (build Docker, push to ECR, force ECS deploy) ---
data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"
    principals { type = "Service", identifiers = ["codebuild.amazonaws.com"] }
    actions   = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.project}-cb-backend-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "codebuild_inline" {
  name = "${var.project}-cb-backend-policy"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ECR push/pull + auth
      {
        Effect: "Allow",
        Action: [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ],
        Resource: "*"
      },
      # S3 artifacts
      {
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource: [
          local.artifacts_bucket_arn,
          local.artifacts_objects_arn
        ]
      },
      # Logs
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "*"
      },
      # ECS force new deployment
      {
        Effect: "Allow",
        Action: [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        Resource: "*"
      }
    ]
  })
}

# --- CodePipeline service role (uses CodeStar connection + triggers CodeBuild) ---
data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect = "Allow"
    principals { type = "Service", identifiers = ["codepipeline.amazonaws.com"] }
    actions   = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.project}-cp-backend-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

resource "aws_iam_role_policy" "codepipeline_inline" {
  name = "${var.project}-cp-backend-policy"
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
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Resource: "*"
      },
      # Use CodeStar connection for GitHub source
      {
        Effect: "Allow",
        Action: ["codestar-connections:UseConnection"],
        Resource: var.github_connection_arn
      }
    ]
  })
}
