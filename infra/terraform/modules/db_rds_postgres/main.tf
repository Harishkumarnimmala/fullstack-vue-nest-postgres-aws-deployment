resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "PostgreSQL access"
  vpc_id      = var.vpc_id

  # allow from app tier SGs
  dynamic "ingress" {
    for_each = var.allowed_sg_ids
    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "App to Postgres"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-db-sg" })
}

resource "aws_db_subnet_group" "pg" {
  name       = "${var.project}-pg-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.project}-pg-subnets" })
}

resource "aws_db_instance" "pg" {
  identifier             = "${var.project}-pg"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20

  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.pg.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true

  tags = merge(var.tags, { Name = "${var.project}-pg" })
}
