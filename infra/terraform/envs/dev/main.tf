############################################
# Compose modules with switchable modes
############################################

module "network" {
  source      = "../../modules/network"
  project     = var.project
  environment = var.environment
  region      = var.region
  tags        = local.common_tags
}

# ECR repositories (backend + frontend)
module "ecr" {
  source      = "../../modules/ecr"
  project     = var.project
  environment = var.environment
  tags        = local.common_tags
}

# Compute (serverless containers)
module "compute_ecs_alb" {
  count                     = var.compute_mode == "ecs_fargate" ? 1 : 0
  source                    = "../../modules/compute_ecs_alb"
  project                   = var.project
  environment               = var.environment
  region                    = var.region
  vpc_id                    = module.network.vpc_id
  public_subnet_ids         = module.network.public_subnet_ids
  container_port            = 3000
  image_url                 = "${module.ecr.backend_repository_url}:latest"
  desired_count             = 1
  enable_autoscaling        = true
  autoscaling_min_capacity  = 1
  autoscaling_max_capacity  = 4
  autoscaling_cpu_target    = 50
  autoscaling_memory_target = 70

  # Plain envs (no secrets here)
  env_vars = {
    PORT    = "3000"
    DB_HOST = var.db_mode == "rds" ? module.db_rds_postgres[0].address : ""
    DB_PORT = "5432"
    DB_NAME = "appdb"
    DB_SSL  = "true"
  }

  # Secret-backed envs
  secret_env_vars = {
    DB_USER     = module.secrets.db_user_arn
    DB_PASSWORD = module.secrets.db_password_arn
  }

  # Grant execution role read access to these secrets
  secrets_manager_arns = [
    module.secrets.db_user_arn,
    module.secrets.db_password_arn
  ]

  healthcheck_path = "/healthz"
  tags             = local.common_tags
}


# DB (RDS)
module "db_rds_postgres" {
  count              = var.db_mode == "rds" ? 1 : 0
  source             = "../../modules/db_rds_postgres"
  project            = var.project
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  allowed_sg_ids     = var.compute_mode == "ecs_fargate" ? [module.compute_ecs_alb[0].ecs_sg_id] : []
  db_name            = "appdb"
  db_user            = var.db_user
  db_password        = var.db_password
  tags               = local.common_tags
}

# CDN (S3+CloudFront, with /api/* -> ALB)
module "cdn" {
  source       = "../../modules/cdn"
  project      = var.project
  environment  = var.environment
  region       = var.region
  alb_dns_name = module.compute_ecs_alb[0].alb_dns
  tags         = local.common_tags
}

# Shared artifacts bucket for CodePipeline
module "cicd_artifacts" {
  source      = "../../modules/cicd_artifacts"
  project     = var.project
  environment = var.environment
  account_id  = var.account_id
  region      = var.region
  tags        = local.common_tags
}

# Single GitHub CodeStar connection (authorize once in console)
module "codestar" {
  source      = "../../modules/codestar"
  project     = var.project
  environment = var.environment
}

module "cicd_backend" {
  source           = "../../modules/cicd_backend"
  project          = var.project
  environment      = var.environment
  region           = var.region
  account_id       = var.account_id
  artifacts_bucket = module.cicd_artifacts.bucket_name
  connection_arn   = module.codestar.connection_arn
  github_owner     = var.github_owner
  github_repo      = var.github_repo
  github_branch    = var.github_branch
  ecr_repo_url     = module.ecr.backend_repository_url
  ecs_cluster_name = module.compute_ecs_alb[0].ecs_cluster_name
  ecs_service_name = module.compute_ecs_alb[0].ecs_service_name
  log_group_name   = module.compute_ecs_alb[0].log_group_name
}

module "cicd_frontend" {
  source               = "../../modules/cicd_frontend"
  project              = var.project
  environment          = var.environment
  region               = var.region
  artifacts_bucket     = module.cicd_artifacts.bucket_name
  connection_arn       = module.codestar.connection_arn
  github_owner         = var.github_owner
  github_repo          = var.github_repo
  github_branch        = var.github_branch
  frontend_bucket_name = module.cdn.frontend_bucket
  distribution_id      = module.cdn.distribution_id
  log_group_name       = module.compute_ecs_alb[0].log_group_name
}

module "secrets" {
  source      = "../../modules/secrets"
  project     = var.project
  environment = var.environment
  db_user     = var.db_user
  db_password = var.db_password
  tags        = local.common_tags
}



# Helpful outputs
output "api_dns" {
  value = module.compute_ecs_alb[0].alb_dns
}

output "frontend_cdn" {
  value = module.cdn.distribution_dns
}

output "db_endpoint" {
  value = var.db_mode == "rds" ? module.db_rds_postgres[0].address : null
}

# New: easy to use with aws ecs update-service, etc.
output "ecs_cluster_name" {
  value = module.compute_ecs_alb[0].ecs_cluster_name
}

output "ecs_service_name" {
  value = module.compute_ecs_alb[0].ecs_service_name
}
