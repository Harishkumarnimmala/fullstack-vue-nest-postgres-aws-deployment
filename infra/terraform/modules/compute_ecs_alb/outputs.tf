output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "ecs_service_name" {
  value = aws_ecs_service.backend.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.backend.arn
}

output "ecs_service_sg_id" {
  value = aws_security_group.ecs_service.id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}
