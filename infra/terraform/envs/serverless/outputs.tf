output "aurora_endpoint" {
  value = module.aurora.cluster_endpoint
}

output "aurora_secret_arn" {
  value = module.aurora.secret_arn
}

output "aurora_sg_id" {
  value = module.aurora.security_group_id
}
