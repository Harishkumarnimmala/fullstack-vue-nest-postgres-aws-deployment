output "security_group_id" {
  description = "RDS SG ID"
  value       = aws_security_group.db.id
}

output "endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "db_name" {
  value = var.db_name
}

output "db_username" {
  value = var.db_username
}
