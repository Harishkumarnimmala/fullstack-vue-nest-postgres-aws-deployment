module "compute" {
  source = "../../modules/compute_ecs_alb"

  project            = var.project
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  health_check_path = "/api/healthz"


  # We'll push the real image later; point to ECR repo with a tag.
  # Keep desired_count = 0 for now so ECS doesn't try to run tasks yet.
  container_image = "${module.ecr_backend.repository_url}:latest"
  desired_count   = 1

  # Defaults: port 3000, cpu 256, memory 512, health /healthz, listener 80
  assign_public_ip = false

  # DB access + secrets
  db_security_group_id = module.db.security_group_id
  db_secret_arn        = module.db.secret_arn

  tags = {
    Environment = "ecs-rds"
  }
}
