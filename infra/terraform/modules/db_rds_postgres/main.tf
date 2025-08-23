# RDS PostgreSQL with Secrets Manager (username/password + connection JSON)

# Subnet group across private subnets
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags = merge(var.tags, {
    Name    = "${var.project}-db-subnets"
    Project = var.project
    Stack   = "db"
  })
}

# Security group for the DB (no ingress yet; we'll allow ECS -> DB later)
resource "aws_security_group" "db" {
  name        = "${var.project}-rds-sg"
  description = "RDS PostgreSQL SG (ingress from backend SG will be added later)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${var.project}-rds-sg"
    Project = var.project
    Stack   = "db"
  })
}

# Strong random password for the DB master user
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# The RDS instance
resource "aws_db_instance" "this" {
  identifier                 = "${var.project}-postgres"
  engine                     = "postgres"
  engine_version             = var.engine_version
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  storage_type               = "gp3"

  db_name                    = var.db_name
  username                   = var.db_username
  password                   = random_password.db.result

  multi_az                   = var.multi_az
  publicly_accessible        = false
  vpc_security_group_ids     = [aws_security_group.db.id]
  db_subnet_group_name       = aws_db_subnet_group.this.name

  backup_retention_period    = 1
  deletion_protection        = false
  skip_final_snapshot        = true
  apply_immediately          = true

  tags = merge(var.tags, {
    Name    = "${var.project}-postgres"
    Project = var.project
    Stack   = "db"
  })
}

# Secrets Manager secret holding full connection details (created after DB)
resource "aws_secretsmanager_secret" "db" {
  name = "${var.project}/db_credentials"
  tags = merge(var.tags, {
    Name    = "${var.project}-db-credentials"
    Project = var.project
    Stack   = "db"
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    username = var.db_username
    password = random_password.db.result
    dbname   = var.db_name
  })
  depends_on = [aws_db_instance.this]
}
