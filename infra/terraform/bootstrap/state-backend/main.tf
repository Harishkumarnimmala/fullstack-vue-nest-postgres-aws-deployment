#############################################
# Bootstrap: S3 remote state + DynamoDB lock
#############################################

provider "aws" {
  region = var.region
}

# S3 state bucket
resource "aws_s3_bucket" "tfstate" {
  bucket        = "tfstate-${var.account_id}-${var.region}"
  force_destroy = false
  tags = { Project = var.project, Environment = "bootstrap" }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB lock table
resource "aws_dynamodb_table" "tf_locks" {
  name         = "tf-locks-fullstack"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project     = var.project
    Environment = "bootstrap"
  }
}
