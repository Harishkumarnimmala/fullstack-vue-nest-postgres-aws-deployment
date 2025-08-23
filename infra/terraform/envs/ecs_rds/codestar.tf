module "codestar" {
  source          = "../../modules/codestar"
  project         = var.project
  connection_name = "github-fullstack"
  provider_type   = "GitHub"

  tags = {
    Environment = "ecs-rds"
  }
}
