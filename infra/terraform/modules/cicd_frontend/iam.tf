data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  artifacts_bucket_arn  = "arn:aws:s3:::${var.artifacts_bucket}"
  artifacts_objects_arn = "arn:aws:s3:::${var.artifacts_bucket}/*"
  frontend_bucket_arn   = "arn:aws:s3:::${var.frontend_bucket}"
  frontend_objects_arn  = "arn:aws:s3:::${var.frontend_bucket}/*"
}

# --- CodeBuild service role (build Vue, upload to S3, invalidate CF) ---
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
  name               = "${var.project}-cb-frontend-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "codebuild_inline" {
  name = "${var.project}-cb-frontend-policy"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Read/write artifacts bucket
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
      # Upload built site to frontend bucket
      {
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource: [
          local.frontend_bucket_arn,
          local.frontend_objects_arn
        ]
      },
      # CloudFront invalidation
      {
        Effect: "Allow",
        Action: [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListDistributions"
        ],
        Resource: "*"
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
      }
    ]
  })
}

# --- CodePipeline service role (GitHub source via CodeStar, trigger CodeBuild) ---
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
  name               = "${var.project}-cp-frontend-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
}

resource "aws_iam_role_policy" "codepipeline_inline" {
  name = "${var.project}-cp-frontend-policy"
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
