module "ecr_backend" {
  source    = "../../modules/ecr"
  project   = var.project
  repo_name = "backend"

  image_tag_mutability = "MUTABLE"   

  tags = {
    Environment = "ecs-rds"
  }
}
