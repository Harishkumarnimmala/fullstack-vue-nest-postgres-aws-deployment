module "aurora" {
  source = "../../modules/aurora_pg_sls"

  project            = var.project
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  db_name         = "appdb"
  master_username = "app_user"

  # Aurora Serverless v2 capacity (adjust later if needed)
  min_acu = 0.5
  max_acu = 2

  # Allow from VPC CIDR (we can tighten to Lambda SG later)
  allow_cidr = "10.0.0.0/16"

  # Secret name in Secrets Manager (JSON with host/port/dbname/username/password)
  secret_name = "${var.project}/serverless/db_credentials"

  tags = {
    Environment = "serverless"
  }
}
