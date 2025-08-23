module "cicd_frontend" {
  source = "../../modules/cicd_frontend"

  project            = var.project
  artifacts_bucket   = module.cicd_artifacts.bucket_name
  frontend_bucket    = module.cdn.bucket_name
  cloudfront_distribution_id = module.cdn.cloudfront_distribution_id

  github_connection_arn = module.codestar.connection_arn
  github_owner          = "Harishkumarnimmala"
  github_repo           = "fullstack-vue-nest-postgres-aws-deployment"
  github_branch         = "main"

  tags = {
    Environment = "ecs-rds"
  }
}
