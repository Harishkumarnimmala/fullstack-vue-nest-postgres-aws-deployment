output "frontend_bucket"  { value = aws_s3_bucket.frontend.id }
output "distribution_id"  { value = aws_cloudfront_distribution.this.id }
output "distribution_dns" { value = aws_cloudfront_distribution.this.domain_name }
