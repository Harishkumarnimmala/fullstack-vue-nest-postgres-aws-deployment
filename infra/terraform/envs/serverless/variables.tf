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
