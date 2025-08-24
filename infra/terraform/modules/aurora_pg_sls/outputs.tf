output "cluster_endpoint" {
  description = "Writer endpoint for the Aurora Serverless cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint (if you add readers later)"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "security_group_id" {
  description = "Aurora cluster security group ID"
  value       = aws_security_group.aurora.id
}

output "secret_arn" {
  description = "ARN of the Secrets Manager JSON with {host,port,dbname,username,password}"
  value       = aws_secretsmanager_secret.db.arn
}

output "cluster_id" {
  value = aws_rds_cluster.this.id
}

