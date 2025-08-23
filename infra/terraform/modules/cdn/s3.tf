data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  bucket_name = lower("frontend-${var.project}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}")
  common_tags = merge(var.tags, {
    Project   = var.project
    Stack     = "cdn"
    Component = "s3"
  })
}

resource "aws_s3_bucket" "frontend" {
  bucket        = local.bucket_name
  force_destroy = false
  tags          = local.common_tags
}

# Ensure bucket owner gets full control on uploaded objects (good for CI/CD uploads)
resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# We will attach a bucket policy after creating CloudFront (OAC) in cloudfront.tf
