resource "aws_codestarconnections_connection" "this" {
  name          = var.connection_name
  provider_type = var.provider_type

  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "cicd"
    Component = "codestar"
  })
}
