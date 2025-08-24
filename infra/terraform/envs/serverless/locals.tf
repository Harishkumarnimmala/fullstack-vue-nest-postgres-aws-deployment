locals {
  common_tags = {
    Project = var.project
    Managed = "terraform"
    Stack   = "serverless"
  }
}
