resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project}-${var.environment}-github"
  provider_type = "GitHub"
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
