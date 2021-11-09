data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  app_name = var.app_name

  account_id = data.aws_caller_identity.current.account_id
  region = data.aws_region.current.name
}

resource "aws_lb_target_group" "main" {
  name = local.app_name

  vpc_id = var.vpc_id

  port = 80
  target_type = "ip"
  protocol = "HTTP"

  health_check {
    port = 80
    path = "/"
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = var.https_listener_arn

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

data "template_file" "container_definitions" {
  template = file("./ecs_app/container_definitions.json")

  vars = {
    tag = "latest"

    name = local.app_name

    account_id = local.account_id
    region     = local.region

    loki_user  = var.loki_user
    loki_pass  = var.loki_pass
  }
}

resource "aws_cloudwatch_log_group" "main" {
  name = "/${local.app_name}/ecs"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "main" {
  family = local.app_name

  cpu = 256
  memory = 1024
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = data.template_file.container_definitions.rendered

  volume {
    name = "app-storage"
  }

  task_role_arn      = var.iam_role_task_execution_arn
  execution_role_arn = var.iam_role_task_execution_arn
}

resource "aws_ecs_service" "main" {
  depends_on = [aws_lb_listener_rule.main]

  name = local.app_name

  launch_type = "FARGATE"
  platform_version = "1.4.0"

  desired_count = 1

  cluster = var.cluster_name

  # revisionを指定しない方法を取ることで整合性を取る
  # task_definition = aws_ecs_task_definition.main.arn
  task_definition = "arn:aws:ecs:ap-northeast-1:${local.account_id}:task-definition/${aws_ecs_task_definition.main.family}"

  network_configuration {
    subnets = var.public_subnet_ids
    security_groups = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name = "nginx"
    container_port = 80
  }
}

resource "aws_security_group" "ecs" {
  name = "${local.app_name}-ecs"
  description = "${local.app_name}-ecs"

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.app_name}-ecs"
  }
}

resource "aws_security_group_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id

  type = "ingress"

  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
