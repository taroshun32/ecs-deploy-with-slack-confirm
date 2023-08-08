resource "aws_ecs_cluster" "app_cluster" {
  name = "app-cluster"
}

resource "aws_ecr_repository" "app_repository" {
  name = "svelte-app"
}

resource "aws_ecs_service" "app_service" {
  name             = "app-service"
  cluster          = aws_ecs_cluster.app_cluster.id
  desired_count    = 0
  platform_version = "1.4.0"

  enable_execute_command             = false
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50
  tags                               = {}

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app-container"
    container_port   = 5173
  }

  network_configuration {
    subnets          = [data.terraform_remote_state.network.outputs.subnet_private_a_id]
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  task_definition = aws_ecs_task_definition.app_task.arn

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }


  health_check_grace_period_seconds = 300

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
    ]
  }
}

resource "aws_security_group" "app" {
  name        = "app"
  description = "Allow inbound ecs-app"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    "Name" = "ecs-app"
  }
}

resource "aws_security_group_rule" "app_ingress" {
  security_group_id        = aws_security_group.app.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "app_egress" {
  security_group_id = aws_security_group.app.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "all"
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecslogs/app"
  retention_in_days = 5
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = <<DEFINITION
[
  {
    "networkMode": "awsvpc",
    "essential": true,
    "image": "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/svelte-app:1.0.0-SNAPSHOT",
    "memoryReservation": 512,
    "name": "app-container",
    "environment" : [
        {
          "name": "TZ",
          "value": "Asia/Tokyo"
        },
        {
          "name": "NODE_ENV",
          "value": "dvelopment"
        },
        {
          "name": "PORT",
          "value": "5173"
        }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.app.name}",
            "awslogs-region": "ap-northeast-1",
            "awslogs-stream-prefix": "app"
        }
    },
    "portMappings": [
      {
        "containerPort": 5173,
        "hostPort": 5173
      }
    ]
  }
]
DEFINITION

}
