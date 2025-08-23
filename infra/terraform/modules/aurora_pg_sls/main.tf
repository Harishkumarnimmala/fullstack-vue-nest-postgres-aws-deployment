# Aurora PostgreSQL Serverless v2 cluster + one writer instance
# Secret in Secrets Manager with {host, port, dbname, username, password}

resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%^&*()-_=+[]{}:,.?" # excludes / @ " and space
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}


# Cluster
resource "aws_rds_cluster" "this" {
  cluster_identifier              = "${var.project}-sls-aurora"
  engine                          = "aurora-postgresql"
  # engine_version                = var.engine_version  # (omit to let AWS default)
  database_name                   = var.db_name
  master_username                 = var.master_username
  master_password                 = random_password.master.result
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.aurora.id]

  storage_encrypted               = true
  backup_retention_period         = 1
  preferred_backup_window         = "03:00-05:00"
  copy_tags_to_snapshot           = true
  deletion_protection             = false

  serverlessv2_scaling_configuration {
    min_capacity = var.min_acu
    max_capacity = var.max_acu
  }

  tags = merge(local.common_tags, { Name = "${var.project}-sls-aurora-cluster" })
}

# Writer instance (Serverless v2 uses this special class)
resource "aws_rds_cluster_instance" "writer" {
  identifier              = "${var.project}-sls-aurora-writer"
  cluster_identifier      = aws_rds_cluster.this.id
  instance_class          = "db.serverless"
  engine                  = aws_rds_cluster.this.engine
  engine_version          = aws_rds_cluster.this.engine_version
  publicly_accessible     = false
  performance_insights_enabled = true

  tags = merge(local.common_tags, { Name = "${var.project}-sls-aurora-writer" })
}

# Secrets Manager JSON with connection info
resource "aws_secretsmanager_secret" "db" {
  name        = var.secret_name
  description = "Aurora Serverless v2 credentials for ${var.project}"
  tags        = merge(local.common_tags, { Name = var.secret_name })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = aws_rds_cluster.this.endpoint
    port     = 5432
    dbname   = var.db_name
    username = var.master_username
    password = random_password.master.result
  })
}
