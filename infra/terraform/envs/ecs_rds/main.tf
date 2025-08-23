module "network" {
  source   = "../../modules/network"
  project  = var.project
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count

  tags = {
    Environment = "ecs-rds"
  }
}
