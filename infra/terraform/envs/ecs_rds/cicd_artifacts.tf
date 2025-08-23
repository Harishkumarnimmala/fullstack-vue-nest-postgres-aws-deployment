module "cicd_artifacts" {
  source        = "../../modules/cicd_artifacts"
  project       = var.project
  force_destroy = false

  tags = {
    Environment = "ecs-rds"
  }
}
