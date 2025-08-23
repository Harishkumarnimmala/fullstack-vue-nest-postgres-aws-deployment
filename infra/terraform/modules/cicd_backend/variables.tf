variable "project" {
  type    = string
  default = "fullstack"
}

# Artifact store (from cicd_artifacts module)
variable "artifacts_bucket" {
  type = string
}

# Build + deploy targets
variable "ecr_repo_url" {
  description = "ECR repo URI to push the backend image"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

# Source (GitHub via CodeStar Connections)
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
  description = "Git branch to build"
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

variable "privileged_mode" {
  description = "Enable Docker daemon in CodeBuild (required for docker build/push)"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
