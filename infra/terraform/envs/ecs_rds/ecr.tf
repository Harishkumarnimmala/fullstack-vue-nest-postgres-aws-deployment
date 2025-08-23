module "ecr_backend" {
  source    = "../../modules/ecr"
  project   = var.project
  repo_name = "backend"

  tags = {
    Environment = "ecs-rds"
  }
}
