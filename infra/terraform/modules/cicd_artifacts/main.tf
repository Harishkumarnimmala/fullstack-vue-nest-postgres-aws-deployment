data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bucket_name = lower("codepipeline-artifacts-${var.project}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}")
  common_tags = merge(var.tags, {
    Project   = var.project
    Stack     = "cicd"
    Component = "artifacts"
  })
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = local.common_tags
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
