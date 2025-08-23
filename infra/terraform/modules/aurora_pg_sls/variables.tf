variable "project" {
  type    = string
  default = "fullstack"
}

variable "vpc_id" {
  description = "VPC for the cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets where the cluster will live"
  type        = list(string)
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "app_user"
}

variable "engine_version" {
  description = "Aurora Postgres engine version (let AWS default if empty)"
  type        = string
  default     = "" # e.g. "15.4"
}

variable "min_acu" {
  description = "Serverless v2 min ACUs"
  type        = number
  default     = 0.5
}

variable "max_acu" {
  description = "Serverless v2 max ACUs"
  type        = number
  default     = 2
}

variable "allow_cidr" {
  description = "CIDR allowed to connect to Postgres (demo: VPC CIDR)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secret_name" {
  description = "Secrets Manager name for DB credentials JSON"
  type        = string
  default     = "fullstack/serverless/db_credentials"
}

variable "tags" {
  type    = map(string)
  default = {}
}
