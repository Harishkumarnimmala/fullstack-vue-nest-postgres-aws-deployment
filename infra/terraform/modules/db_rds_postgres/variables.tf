variable "project" {
  type    = string
  default = "fullstack"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "app_user"
}

variable "engine_version" {
  type    = string
  default = "16.3"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Allow RDS to auto-grow storage up to this GiB
variable "max_allocated_storage" {
  type        = number
  description = "Upper limit for RDS storage auto-scaling (GiB)"
  default     = 100
}

