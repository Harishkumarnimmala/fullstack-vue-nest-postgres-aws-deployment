variable "project" {
  type    = string
  default = "fullstack"
}

variable "force_destroy" {
  description = "Allow terraform to delete the bucket even if it has objects"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
