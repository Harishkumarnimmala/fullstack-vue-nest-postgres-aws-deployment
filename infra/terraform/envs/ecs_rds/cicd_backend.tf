module "cicd_backend" {
  source = "../../modules/cicd_backend"

  project          = var.project
  artifacts_bucket = module.cicd_artifacts.bucket_name

  # Targets
  ecr_repo_url     = module.ecr_backend.repository_url
  ecs_cluster_name = module.compute.ecs_cluster_name
  ecs_service_name = module.compute.ecs_service_name

  # GitHub (via CodeStar)
  github_connection_arn = module.codestar.connection_arn
  github_owner          = "Harishkumarnimmala"
  github_repo           = "fullstack-vue-nest-postgres-aws-deployment"
  github_branch         = "main"

  tags = {
    Environment = "ecs-rds"
  }
}
