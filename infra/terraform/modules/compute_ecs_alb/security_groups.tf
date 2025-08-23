# --- Security Groups for ALB and ECS service ---

locals {
  sg_tags = merge(var.tags, {
    Project   = var.project
    Stack     = "compute"
    Component = "sg"
  })
}

# ALB SG: allow HTTP from internet, egress anywhere (to ECS)
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.sg_tags, { Name = "${var.project}-alb-sg" })
}

# ECS Service SG: only ALB can reach the container port; egress anywhere (DB, internet via NAT)
resource "aws_security_group" "ecs_service" {
  name        = "${var.project}-ecs-svc-sg"
  description = "ECS service security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From ALB to container"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.sg_tags, { Name = "${var.project}-ecs-svc-sg" })
}
