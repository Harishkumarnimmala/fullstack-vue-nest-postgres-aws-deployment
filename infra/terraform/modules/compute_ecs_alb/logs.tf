resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project}-backend"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "compute"
    Component = "logs"
  })
}
