terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}


# VPC with 2x public + 2x private subnets across 2 AZs

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "${var.project}-vpc"
  cidr    = "10.0.0.0/16"
  azs     = ["${var.region}a","${var.region}b"]

  public_subnets  = ["10.0.1.0/24","10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24","10.0.12.0/24"]

  enable_nat_gateway = false
  enable_dns_support   = true
  enable_dns_hostnames = true

  # Global tags applied to most created resources
  tags = {
    Project     = var.project
    Environment = "dev"
    Owner       = "Harish"
  }

  # Ensure the VPC itself has a Name in the console
  vpc_tags = {
    Name = "${var.project}-vpc"
  }

  # Give subnets readable names too
  public_subnet_tags = {
    Name = "${var.project}-public"
  }
  private_subnet_tags = {
    Name = "${var.project}-private"
  }
}

# Security Group for ECS tasks (referenced now, used later by ECS)
resource "aws_security_group" "ecs" {
  name_prefix = "${var.project}-ecs-sg-"   # <— use name_prefix so a new SG can be created
  description = "ECS tasks SG"
  vpc_id      = module.vpc.vpc_id

  # Allow ALB -> ECS on 3000
  ingress {
    description     = "From ALB to container port"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Outbound to internet (for package downloads, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-ecs-sg"
    Project     = var.project
    Environment = "dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Security Group for the database: only allow 5432 from ECS SG
resource "aws_security_group" "db" {
  name        = "${var.project}-db-sg"
  description = "PostgreSQL access from ECS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Postgres from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-db-sg"
    Project     = var.project
    Environment = "dev"
  }
}

# DB subnet group uses private subnets
resource "aws_db_subnet_group" "pg" {
  name       = "${var.project}-pg-subnets"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name        = "${var.project}-pg-subnets"
    Project     = var.project
    Environment = "dev"
  }
}

# RDS PostgreSQL instance (dev-friendly)
resource "aws_db_instance" "pg" {
  identifier              = "${var.project}-pg"
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20

  db_name                 = "appdb"
  username                = var.db_user
  password                = var.db_password

  db_subnet_group_name    = aws_db_subnet_group.pg.name
  vpc_security_group_ids  = [aws_security_group.db.id]

  publicly_accessible     = false      # keep DB private
  multi_az                = false      # dev; set true in prod
  skip_final_snapshot     = true       # dev convenience

  tags = {
    Name        = "${var.project}-pg"
    Project     = var.project
    Environment = "dev"
  }
}

# CloudWatch log group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project}"
  retention_in_days = 7
}

# ECS task execution role (pulls from ECR, writes logs)
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project}-ecs-task-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_ecrlogs" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecr_repository" "backend" {
  name = "fullstack-backend"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
  tags = { Project = var.project, Environment = "dev" }
}

resource "aws_ecr_repository" "frontend" {
  name = "fullstack-frontend"
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
  tags = { Project = var.project, Environment = "dev" }
}

# ALB SG: allow HTTP from anywhere
resource "aws_security_group" "alb" {
  name   = "${var.project}-alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-alb-sg"
    Project     = var.project
    Environment = "dev"
  }
}


# Application Load Balancer
resource "aws_lb" "api" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]

  tags = { Name = "${var.project}-alb", Project = var.project, Environment = "dev" }
}

resource "aws_lb_target_group" "api" {
  name        = "${var.project}-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path                = "/greeting"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }
  tags = { Name = "${var.project}-tg", Project = var.project, Environment = "dev" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.api.arn
  port     = 80
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"
}

# Task definition for backend
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "backend",
      image     = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/fullstack-backend:latest",
      essential = true,
      portMappings = [{ containerPort = 3000, hostPort = 3000 }],
      environment = [
        { name = "PORT", value = "3000" },
        { name = "DB_HOST", value = aws_db_instance.pg.address },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_NAME", value = "appdb" },
        { name = "DB_USER", value = var.db_user },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "DB_SSL", value = "true" }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
          "awslogs-region"        = var.region,
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])
}

# ECS service (dev: tasks in public subnets, no NAT required)
resource "aws_ecs_service" "backend" {
  name            = "${var.project}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.public_subnets
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "backend"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket        = "${var.project}-codepipeline-${var.account_id}-${var.region}"
  force_destroy = true
  tags = { Project = var.project, Environment = "dev" }
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket                  = aws_s3_bucket.codepipeline_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project}-github"
  provider_type = "GitHub"
  tags = { Project = var.project, Environment = "dev" }
}

# ----- CodeBuild service role -----
resource "aws_iam_role" "codebuild_backend" {
  name = "${var.project}-cb-backend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "codebuild.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

data "aws_iam_policy_document" "codebuild_backend_inline" {
  statement {
    actions = [
      "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer", "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:GetObjectVersion", "s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.codepipeline_artifacts.arn, "${aws_s3_bucket.codepipeline_artifacts.arn}/*"]
  }
  statement {
    actions   = ["ecs:UpdateService", "ecs:DescribeServices", "ecs:DescribeTaskDefinition"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_backend_inline" {
  role   = aws_iam_role.codebuild_backend.name
  policy = data.aws_iam_policy_document.codebuild_backend_inline.json
}

# ----- CodePipeline service role -----
resource "aws_iam_role" "codepipeline_backend" {
  name = "${var.project}-cp-backend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "codepipeline.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

data "aws_iam_policy_document" "codepipeline_backend_inline" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:GetBucketVersioning", "s3:GetObjectVersion", "s3:ListBucket"]
    resources = [aws_s3_bucket.codepipeline_artifacts.arn, "${aws_s3_bucket.codepipeline_artifacts.arn}/*"]
  }
  statement {
    actions   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
    resources = ["*"]
  }
  statement {
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github.arn]
  }
}

resource "aws_iam_role_policy" "codepipeline_backend_inline" {
  role   = aws_iam_role.codepipeline_backend.name
  policy = data.aws_iam_policy_document.codepipeline_backend_inline.json
}

resource "aws_codebuild_project" "backend" {
  name         = "${var.project}-backend-build"
  service_role = aws_iam_role.codebuild_backend.arn
  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true  # needed to run Docker
    environment_variable {
      name  = "AWS_REGION"
      value = var.region
    }
    environment_variable {
      name  = "ACCOUNT_ID"
      value = var.account_id
    }
    environment_variable {
      name  = "ECR_REPO"
      value = aws_ecr_repository.backend.repository_url
    }
    environment_variable {
      name  = "ECS_CLUSTER"
      value = aws_ecs_cluster.this.name
    }
    environment_variable {
      name  = "ECS_SERVICE"
      value = aws_ecs_service.backend.name
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = <<-YAML
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws --version
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
            - COMMIT_SHA=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c1-7)
            - IMAGE_TAG=$${COMMIT_SHA:-latest}

        build:
          commands:
            - echo Building Docker image...
            - cd backend
            - docker build -t $ECR_REPO:$IMAGE_TAG -t $ECR_REPO:latest .
        post_build:
          commands:
            - echo Pushing images to ECR...
            - docker push $ECR_REPO:$IMAGE_TAG
            - docker push $ECR_REPO:latest
            - echo Forcing ECS deployment to pick up latest image...
            - aws ecs update-service --cluster "$ECS_CLUSTER" --service "$ECS_SERVICE" --force-new-deployment --region $AWS_REGION
      artifacts:
        files:
          - '**/*'
    YAML
  }
  logs_config {
    cloudwatch_logs { group_name = aws_cloudwatch_log_group.ecs.name }
  }
}

resource "aws_codepipeline" "backend" {
  name     = "${var.project}-backend-pipeline"
  role_arn = aws_iam_role.codepipeline_backend.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAndDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      configuration = {
        ProjectName = aws_codebuild_project.backend.name
      }
    }
  }

  tags = {
    Project     = var.project
    Environment = "dev"
  }
}


