data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    Project   = var.project
    Stack     = "serverless"
    Component = "aurora"
  })
}

# Subnet group for Aurora in your private subnets
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-sls-aurora-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(local.common_tags, { Name = "${var.project}-sls-aurora-subnets" })
}

# Security group for Aurora; allow Postgres from VPC CIDR (we’ll tighten later to Lambda SG)
resource "aws_security_group" "aurora" {
  name        = "${var.project}-sls-aurora-sg"
  description = "Aurora Serverless v2 SG"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = "${var.project}-sls-aurora-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_vpc" {
  security_group_id = aws_security_group.aurora.id
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allow_cidr
  description       = "Allow Postgres from VPC CIDR (demo)"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.aurora.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Egress"
}
