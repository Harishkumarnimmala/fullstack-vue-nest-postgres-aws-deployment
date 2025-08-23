data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    Project   = var.project
    Stack     = "serverless"
    Component = "lambda-api"
  })
}

# --- IAM: Lambda assume-role trust policy ---
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project}-sls-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

# Managed policies for logs and VPC ENI access
resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Allow reading the Aurora secret JSON
data "aws_iam_policy_document" "read_secret" {
  statement {
    sid     = "ReadAuroraSecret"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [var.aurora_secret_arn]
  }
}

resource "aws_iam_policy" "read_secret" {
  name   = "${var.project}-sls-api-read-secret"
  policy = data.aws_iam_policy_document.read_secret.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "attach_read_secret" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.read_secret.arn
}

# --- Networking: Lambda SG and allow to Aurora on 5432 ---
resource "aws_security_group" "lambda_sg" {
  name        = "${var.project}-sls-api-sg"
  description = "Lambda security group for serverless API"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = "${var.project}-sls-api-sg" })
}

resource "aws_vpc_security_group_egress_rule" "lambda_all_out" {
  security_group_id = aws_security_group.lambda_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Lambda egress"
}

# Allow Lambda to reach Aurora on 5432 (adds an ingress rule on the Aurora SG)
resource "aws_vpc_security_group_ingress_rule" "aurora_from_lambda" {
  security_group_id            = var.aurora_sg_id
  referenced_security_group_id = aws_security_group.lambda_sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow Lambda API to connect to Aurora"
}
