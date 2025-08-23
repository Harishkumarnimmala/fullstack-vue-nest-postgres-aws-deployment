resource "aws_ecr_repository" "this" {
  name                 = "${var.project}/${var.repo_name}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "ecr"
    Component = var.repo_name
  })
}

# Optional: keep the last 10 images, expire untagged images
# Keep it simple: only expire untagged images after 7 days
resource "aws_ecr_lifecycle_policy" "keep_last_10" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire untagged images after 7 days",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 7
        },
        action = { type = "expire" }
      }
    ]
  })
}

