################
# RDS PROXY
################

locals {
  rds_proxy_tags = merge(var.tags, {
    Project   = var.project
    Stack     = "serverless"
    Component = "rds-proxy"
  })
}

# IAM role so the proxy can read DB creds from Secrets Manager
resource "aws_iam_role" "rds_proxy" {
  name               = "${var.project}-rds-proxy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "rds.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.rds_proxy_tags
}

resource "aws_iam_role_policy" "rds_proxy_sm" {
  name = "${var.project}-rds-proxy-sm"
  role = aws_iam_role.rds_proxy.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = var.aurora_secret_arn
    }]
  })
}

# SG for the proxy ENIs
resource "aws_security_group" "rds_proxy" {
  name        = "${var.project}-rds-proxy-sg"
  description = "Lambda to RDS Proxy"
  vpc_id      = var.vpc_id
  tags        = merge(local.rds_proxy_tags, { Name = "${var.project}-rds-proxy-sg" })
}

# Allow Lambda -> Proxy on 5432
resource "aws_vpc_security_group_ingress_rule" "lambda_to_proxy" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.lambda_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Lambda to RDS Proxy 5432"
}

# Allow Proxy -> Aurora on 5432
resource "aws_vpc_security_group_egress_rule" "proxy_to_aurora" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = var.aurora_sg_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "RDS Proxy to Aurora 5432"
}

# Make sure Aurora SG accepts from Proxy SG (ingress 5432)
resource "aws_vpc_security_group_ingress_rule" "aurora_allow_from_proxy" {
  security_group_id            = var.aurora_sg_id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "Allow RDS Proxy SG to Aurora 5432"
}

# The proxy itself
resource "aws_db_proxy" "this" {
  name                 = "${var.project}-rds-proxy"
  engine_family        = "POSTGRESQL"
  idle_client_timeout  = 1800
  require_tls          = true
  role_arn             = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]
  vpc_subnet_ids       = var.private_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = var.aurora_secret_arn
    iam_auth    = "DISABLED"
  }

  tags = local.rds_proxy_tags
}

# Target group & pool config
resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    max_connections_percent        = 50
    max_idle_connections_percent   = 50
    connection_borrow_timeout      = 120
    session_pinning_filters        = [] # leave empty for better pooling
  }

  depends_on = [aws_db_proxy.this]
}

# Register the Aurora cluster as the proxy target
resource "aws_db_proxy_target" "aurora" {
  db_proxy_name         = aws_db_proxy.this.name
  target_group_name     = aws_db_proxy_default_target_group.this.name
  db_cluster_identifier = var.aurora_cluster_id
}

# (Optional) export the endpoint for the next step
output "rds_proxy_endpoint" {
  value = aws_db_proxy.this.endpoint
}
