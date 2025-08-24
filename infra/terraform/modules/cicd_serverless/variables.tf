variable "project" {
  description = "Project prefix (e.g., fullstack)"
  type        = string
}

variable "artifacts_bucket" {
  description = "S3 bucket for CodePipeline/CodeBuild artifacts"
  type        = string
}

variable "github_connection_arn" {
  description = "CodeStar Connections ARN for GitHub"
  type        = string
}

variable "repo_owner" {
  description = "GitHub org/user that owns the repo"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "repo_branch" {
  description = "Branch to build from"
  type        = string
  default     = "main"
}

variable "lambda_function_name" {
  description = "Target Lambda function to update (serverless API)"
  type        = string
  default     = "fullstack-sls-api"
}

variable "build_image" {
  description = "CodeBuild image"
  type        = string
  default     = "aws/codebuild/standard:7.0"
}

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
