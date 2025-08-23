variable "project" {
  type    = string
  default = "fullstack"
}

# ALB DNS name to route /api/* to (from the compute module)
variable "alb_dns_name" {
  type        = string
  description = "Public DNS of the ALB (e.g., fullstack-alb-xyz.eu-central-1.elb.amazonaws.com)"
}

# Frontend SPA defaults
variable "index_document" {
  type    = string
  default = "index.html"
}

variable "error_document" {
  type    = string
  default = "index.html" # SPA fallback
}

# Path pattern for backend API routed to ALB
variable "api_path_pattern" {
  type    = string
  default = "/api/*"
}

# CloudFront price class to control cost
variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "tags" {
  type    = map(string)
  default = {}
}
