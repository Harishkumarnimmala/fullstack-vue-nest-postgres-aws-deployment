variable "project" {
  type    = string
  default = "fullstack"
}

# Artifact store (from cicd_artifacts)
variable "artifacts_bucket" {
  type = string
}

# Frontend deploy target (from cdn module)
variable "frontend_bucket" {
  description = "S3 bucket name for the built frontend"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID to invalidate after deploy"
  type        = string
}

# GitHub source (via CodeStar connection)
variable "github_connection_arn" {
  description = "AWS CodeStar Connections ARN for GitHub"
  type        = string
}

variable "github_owner" {
  description = "GitHub org/user"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "Branch to build"
  type        = string
  default     = "main"
}

# CodeBuild settings
variable "build_image" {
  description = "CodeBuild container image"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "compute_type" {
  description = "Build compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "tags" {
  type    = map(string)
  default = {}
}
