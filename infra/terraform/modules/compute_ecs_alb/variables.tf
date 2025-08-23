variable "project" {
  type    = string
  default = "fullstack"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

# Container/task settings
variable "container_image" {
  description = "ECR image URI for the NestJS backend"
  type        = string
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "cpu" {
  description = "Fargate task CPU (e.g., 256, 512, 1024)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB (e.g., 512, 1024, 2048)"
  type        = number
  default     = 512
}

# ALB + health check
variable "health_check_path" {
  type    = string
  default = "/healthz"
}

variable "listener_port" {
  type    = number
  default = 80
}

# Networking
variable "assign_public_ip" {
  description = "Whether tasks get public IPs (keep false for private subnets)"
  type        = bool
  default     = false
}

# Security + Secrets
variable "db_security_group_id" {
  description = "Security Group ID of the RDS instance to allow ingress from ECS"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for the DB credentials JSON"
  type        = string
}

# Logging
variable "log_retention_days" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
