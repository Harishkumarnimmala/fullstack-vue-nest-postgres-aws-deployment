locals {
  vpce_tags = merge(var.tags, {
    Project   = var.project
    Stack     = "serverless"
    Component = "vpce-secretsmanager"
  })
}

# SG for the VPC endpoint ENIs
resource "aws_security_group" "vpce_secretsmanager_sg" {
  name        = "${var.project}-vpce-secretsmanager-sg"
  description = "Allow Lambda to access Secrets Manager via VPC endpoint"
  vpc_id      = var.vpc_id
  tags        = merge(local.vpce_tags, { Name = "${var.project}-vpce-secretsmanager-sg" })
}

# Allow HTTPS from the Lambda SG to the endpoint ENIs
resource "aws_vpc_security_group_ingress_rule" "vpce_allow_from_lambda_https" {
  security_group_id            = aws_security_group.vpce_secretsmanager_sg.id
  referenced_security_group_id = aws_security_group.lambda_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "Lambda to Secrets Manager endpoint 443"
}

# Optional: endpoint policy (demo-friendly)
data "aws_iam_policy_document" "vpce_sm_policy" {
  statement {
    effect = "Allow"
    actions   = ["secretsmanager:*"]
    resources = ["*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# Interface VPC Endpoint for Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce_secretsmanager_sg.id]

  policy = data.aws_iam_policy_document.vpce_sm_policy.json

  tags = local.vpce_tags
}
