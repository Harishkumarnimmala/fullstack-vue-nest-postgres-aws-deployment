# Region data (for logs)
data "aws_region" "current" {}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"
  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "compute"
    Component = "ecs-cluster"
  })
}

# --- Task Definition (Fargate) ---
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project}-backend"
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.container_image
      essential = true

      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "DB_SSL",   value = "true" } # our service reads this flag
      ]

      # Map individual keys from the Secrets Manager JSON to env vars
      secrets = [
        { name = "DB_HOST",     valueFrom = "${var.db_secret_arn}:host::" },
        { name = "DB_PORT",     valueFrom = "${var.db_secret_arn}:port::" },
        { name = "DB_NAME",     valueFrom = "${var.db_secret_arn}:dbname::" },
        { name = "DB_USER",     valueFrom = "${var.db_secret_arn}:username::" },
        { name = "DB_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" }
      ]
    }
  ])
}

# --- ECS Service (behind ALB) ---
resource "aws_ecs_service" "backend" {
  name            = "${var.project}-backend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  lifecycle {
    ignore_changes = [desired_count]
  }


  tags = merge(var.tags, {
    Project   = var.project
    Stack     = "compute"
    Component = "ecs-service"
  })
}

# --- Allow ECS service to reach RDS on 5432 ---
resource "aws_security_group_rule" "allow_ecs_to_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.db_security_group_id
  source_security_group_id = aws_security_group.ecs_service.id
  description              = "Allow ECS service to connect to RDS"
}
