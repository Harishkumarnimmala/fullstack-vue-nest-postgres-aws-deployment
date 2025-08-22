variable "project"            { type = string }
variable "environment"        { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "allowed_sg_ids"     { type = list(string) } # who can reach 5432
variable "db_name"            { type = string }
variable "db_user"            { type = string }
variable "db_password"        { type = string }
variable "tags"               { type = map(string) }

variable "max_allocated_storage" {
  type    = number
  default = 100  # GB ceiling for storage autoscaling
}

variable "backup_retention_days" {
  type    = number
  default = 1    # dev-friendly; raise in prod
}

variable "performance_insights" {
  type    = bool
  default = true
}

