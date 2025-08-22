variable "project"     { type = string }
variable "environment" { type = string }
variable "db_user"     { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "tags" { type = map(string) }
