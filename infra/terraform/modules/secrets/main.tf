resource "aws_secretsmanager_secret" "db_user" {
  name                    = "${var.project}/${var.environment}/db_user"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db_user_v" {
  secret_id     = aws_secretsmanager_secret.db_user.id
  secret_string = var.db_user
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project}/${var.environment}/db_password"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password_v" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}
