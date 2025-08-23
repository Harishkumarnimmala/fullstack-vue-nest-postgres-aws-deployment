# --- IAM for ECS tasks ---

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Execution role: pulls from ECR, writes logs, etc.
resource "aws_iam_role" "task_execution_role" {
  name               = "${var.project}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = merge(var.tags, { Project = var.project, Stack = "compute" })
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role: permissions the app container uses (Secrets Manager read)
resource "aws_iam_role" "task_role" {
  name               = "${var.project}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = merge(var.tags, { Project = var.project, Stack = "compute" })
}

data "aws_iam_policy_document" "allow_db_secret" {
  statement {
    sid     = "AllowReadDBSecret"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.db_secret_arn
    ]
  }
}

resource "aws_iam_policy" "allow_db_secret" {
  name   = "${var.project}-allow-db-secret"
  policy = data.aws_iam_policy_document.allow_db_secret.json
}

resource "aws_iam_role_policy_attachment" "task_role_allow_db_secret" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.allow_db_secret.arn
}
