variable "project" {
  type        = string
  description = "Project tag prefix"
  default     = "fullstack"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "How many AZs to use"
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}

