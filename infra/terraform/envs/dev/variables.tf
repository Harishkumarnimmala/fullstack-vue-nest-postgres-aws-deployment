variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type = string
}

# NEW: deployment modes
variable "compute_mode" {
  type        = string
  description = "ecs_fargate | (future: ec2_asg | lambda_apigw)"
  validation {
    condition     = contains(["ecs_fargate"], var.compute_mode)
    error_message = "Only ecs_fargate supported in this step."
  }
}

variable "db_mode" {
  type        = string
  description = "rds | (future: aurora_serverless)"
  validation {
    condition     = contains(["rds"], var.db_mode)
    error_message = "Only rds supported in this step."
  }
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "Harish"
  }
}
