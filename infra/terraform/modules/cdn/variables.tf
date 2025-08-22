variable "project"        { type = string }
variable "environment"    { type = string }
variable "region"         { type = string }
variable "alb_dns_name"   { type = string } # API origin for /api/*
variable "tags"           { type = map(string) }
