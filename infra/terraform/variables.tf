variable "project" {
  type    = string
  default = "fullstack-demo"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "account_id" {
  type = string
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type = string
}

variable "github_owner" {
  type    = string
  default = "Harishkumarnimmala"
}

variable "github_repo" {
  type    = string
  default = "fullstack-vue-nest-postgres-aws-deployment"
}

variable "github_branch" {
  type    = string
  default = "main"
}



