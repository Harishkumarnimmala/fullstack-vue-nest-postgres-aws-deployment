output "db_user_arn"     { value = aws_secretsmanager_secret.db_user.arn }
output "db_password_arn" { value = aws_secretsmanager_secret.db_password.arn }
