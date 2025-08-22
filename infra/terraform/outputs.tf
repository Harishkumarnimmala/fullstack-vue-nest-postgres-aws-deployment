output "vpc_id"          { value = module.vpc.vpc_id }
output "public_subnets"  { value = module.vpc.public_subnets }
output "private_subnets" { value = module.vpc.private_subnets }

output "db_endpoint" {
  value = aws_db_instance.pg.address
}

output "db_port" {
  value = aws_db_instance.pg.port
}

output "alb_dns" {
  value = aws_lb.api.dns_name
}

output "api_test_url" {
  value = "http://${aws_lb.api.dns_name}/greeting"
}

output "codepipeline_bucket" {
  value = aws_s3_bucket.codepipeline_artifacts.id
}

output "codestar_connection_arn" {
  value = aws_codestarconnections_connection.github.arn
}

output "backend_pipeline_name" {
  value = aws_codepipeline.backend.name
}

output "frontend_bucket" {
  value = aws_s3_bucket.frontend.id
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "frontend_pipeline_name" {
  value = aws_codepipeline.frontend.name
}
