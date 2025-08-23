output "bucket_name" {
  value       = aws_s3_bucket.artifacts.bucket
  description = "CodePipeline artifacts bucket name"
}

output "bucket_arn" {
  value       = aws_s3_bucket.artifacts.arn
  description = "CodePipeline artifacts bucket ARN"
}
