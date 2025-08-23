output "connection_arn" {
  value       = aws_codestarconnections_connection.this.arn
  description = "ARN of the CodeStar connection"
}
