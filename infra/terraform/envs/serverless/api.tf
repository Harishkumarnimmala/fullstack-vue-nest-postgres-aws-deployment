module "serverless_api" {
  source = "../../modules/serverless_api"

  project = var.project

  # VPC so Lambda can reach Aurora
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  # Aurora integration
  aurora_secret_arn = module.aurora.secret_arn
  aurora_sg_id      = module.aurora.security_group_id

  # Lambda defaults (can tweak later)
  lambda_memory_mb = 512
  lambda_timeout_s = 10
  lambda_runtime   = "nodejs20.x"
  lambda_arch      = "x86_64"

  # HTTP API
  api_stage_name = "$default"

  tags = {
    Environment = "serverless"
  }
}

output "serverless_api_url" {
  value = module.serverless_api.api_endpoint
}
