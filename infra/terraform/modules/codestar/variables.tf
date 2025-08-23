variable "project" {
  type    = string
  default = "fullstack"
}

variable "connection_name" {
  description = "Name for the CodeStar connection"
  type        = string
  default     = "github-fullstack"
}

variable "provider_type" {
  description = "SCM provider"
  type        = string
  default     = "GitHub"
}

variable "tags" {
  type    = map(string)
  default = {}
}
