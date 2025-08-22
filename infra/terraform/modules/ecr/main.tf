resource "aws_ecr_repository" "backend" {
  name = "fullstack-backend"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
  tags         = var.tags
}

resource "aws_ecr_repository" "frontend" {
  name = "fullstack-frontend"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
  tags         = var.tags
}
