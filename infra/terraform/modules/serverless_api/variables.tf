variable "project" {
  type    = string
  default = "fullstack"
}

# VPC context for Lambda to reach Aurora
variable "vpc_id" {
  description = "VPC where the Lambda runs"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for Lambda ENIs"
  type        = list(string)
}

# Aurora integration
variable "aurora_secret_arn" {
  description = "Secrets Manager ARN with {host,port,dbname,username,password}"
  type        = string
}

variable "aurora_sg_id" {
  description = "Security Group ID of the Aurora cluster"
  type        = string
}

# Lambda settings
variable "lambda_memory_mb" {
  type    = number
  default = 512
}

variable "lambda_timeout_s" {
  type    = number
  default = 10
}

variable "lambda_runtime" {
  type    = string
  default = "nodejs20.x"
}

variable "lambda_arch" {
  type    = string
  default = "x86_64" # or "arm64"
}

# API Gateway
variable "api_stage_name" {
  type    = string
  default = "$default"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "lambda_reserved_concurrency" {
  description = "Hard cap for concurrent Lambda executions (protects DB)"
  type        = number
  default     = 10
}

variable "aurora_cluster_id" {
  description = "Aurora cluster identifier used by RDS Proxy target"
  type        = string
}

variable "alarm_topic_arn" {
  description = "SNS topic ARN for alarm notifications "
  type        = string
  default     = null
}


