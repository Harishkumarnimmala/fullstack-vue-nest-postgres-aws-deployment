output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "db_endpoint" {
  value = module.db.endpoint
}

output "db_port" {
  value = module.db.port
}

output "db_secret_arn" {
  value = module.db.secret_arn
}

output "db_security_group_id" {
  value = module.db.security_group_id
}

output "db_name" {
  value = module.db.db_name
}

output "db_username" {
  value = module.db.db_username
}

output "ecr_backend_repo_url" {
  value = module.ecr_backend.repository_url
}
