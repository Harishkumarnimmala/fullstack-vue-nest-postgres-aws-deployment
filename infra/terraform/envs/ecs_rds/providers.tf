terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0" }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "db" {
  source             = "../../modules/db_rds_postgres"
  project            = var.project
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  # sensible demo defaults; tweak if needed
  db_name         = "appdb"
  db_username     = "app_user"
  engine_version  = "16.3"
  instance_class  = "db.t4g.micro"
  allocated_storage = 20
  multi_az        = false

  tags = {
    Environment = "ecs-rds"
  }
}
