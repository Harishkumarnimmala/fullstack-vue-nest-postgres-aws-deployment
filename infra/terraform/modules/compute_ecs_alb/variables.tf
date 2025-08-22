variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "container_port" {
  type = number
}

variable "image_url" {
  type = string
}

variable "desired_count" {
  type = number
}

# plain env vars (non-secret)
variable "env_vars" {
  type = map(string)
}

# NAME -> Secret ARN (for ECS "secrets")
variable "secret_env_vars" {
  type    = map(string)
  default = {}
}

# allow the task exec role to read these ARNs
variable "secrets_manager_arns" {
  type    = list(string)
  default = []
}

variable "healthcheck_path" {
  type = string
}

variable "tags" {
  type = map(string)
}

# --- autoscaling ---
variable "enable_autoscaling" {
  type    = bool
  default = true
}

variable "autoscaling_min_capacity" {
  type    = number
  default = 1
}

variable "autoscaling_max_capacity" {
  type    = number
  default = 3
}

variable "autoscaling_cpu_target" {
  type    = number
  default = 50
}

variable "autoscaling_memory_target" {
  type    = number
  default = 70
}
