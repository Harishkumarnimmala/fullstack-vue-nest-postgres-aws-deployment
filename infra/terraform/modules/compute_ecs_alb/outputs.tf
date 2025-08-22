output "alb_dns"          { value = aws_lb.api.dns_name }
output "ecs_cluster_name" { value = aws_ecs_cluster.this.name }
output "ecs_service_name" { value = aws_ecs_service.backend.name }
output "log_group_name"   { value = aws_cloudwatch_log_group.ecs.name }
output "ecs_sg_id"        { value = aws_security_group.ecs.id }
