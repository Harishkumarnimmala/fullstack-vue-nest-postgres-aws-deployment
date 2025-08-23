# ECS Service DesiredCount autoscaling (target tracking)

locals {
  asg_resource_id = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.backend.name}"
}

resource "aws_appautoscaling_target" "ecs" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.asg_max_capacity
  min_capacity       = var.asg_min_capacity
  resource_id        = local.asg_resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_target" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.project}-ecs-cpu-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.asg_cpu_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory_target" {
  count              = var.enable_autoscaling && var.asg_memory_target != null ? 1 : 0
  name               = "${var.project}-ecs-mem-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.asg_memory_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Scale by ALB requests per target (bursty traffic)
resource "aws_appautoscaling_policy" "req_target" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.project}-ecs-req-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      # Format: app/<lb-name>/<lb-id>/targetgroup/<tg-name>/<tg-id>
      resource_label = "${aws_lb.this.arn_suffix}/${aws_lb_target_group.backend.arn_suffix}"

    }
    target_value       = var.asg_requests_per_target
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

