output "state_bucket" {
  description = "Name of the S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.tfstate.bucket
}

output "lock_table" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.tf_locks.name
}
