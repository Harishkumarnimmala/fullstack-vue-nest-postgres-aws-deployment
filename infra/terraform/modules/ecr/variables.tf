variable "project" {
  type    = string
  default = "fullstack"
}

# Name for the ECR repository (e.g., "backend")
variable "repo_name" {
  type    = string
  default = "backend"
}

# Whether image tags can be overwritten
variable "image_tag_mutability" {
  type    = string
  default = "IMMUTABLE" # or "MUTABLE"
}

# Enable vulnerability scanning on push
variable "scan_on_push" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
