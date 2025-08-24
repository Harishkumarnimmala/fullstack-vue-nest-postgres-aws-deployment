variable "project" {
  type    = string
  default = "fullstack"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

# Reuse existing VPC + subnets from Approach 1
# (we’ll pass these in shortly; you already have the IDs)
variable "vpc_id" {
  type        = string
  description = "Existing VPC ID (reuse from Approach 1)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for Lambda + Aurora"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "artifacts_bucket" {
  description = "S3 bucket used by CodePipeline/CodeBuild for artifacts"
  type        = string
}

variable "repo_owner" {
  description = "GitHub org/user"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "repo_branch" {
  description = "Git branch to build"
  type        = string
  default     = "main"
}

variable "github_connection_arn" {
  description = "CodeStar Connections ARN for GitHub"
  type        = string
}
