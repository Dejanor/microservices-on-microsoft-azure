resource "aws_ecs_task_definition" "assets" {
  family                   = "${local.full_environment_prefix}-assets"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  cpu = 256
  memory = 512

  container_definitions    = <<DEFINITION
[
  {
    "name": "assets",
    "image": "watchn/watchn-assets:${var.image_tag}",
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 8080
      }
    ],
    "healthcheck": {
      "command" : [ 
        "CMD-SHELL", "curl -f http://localhost:8080/health.html || exit 1"
      ],
      "interval" : 30,
      "retries" : 3,
      "startPeriod" : 15,
      "timeout" : 10
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.logs.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_ecs_service" "assets" {
  name             = "${local.full_environment_prefix}-assets"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.assets.arn
  desired_count    = 3
  platform_version = "1.4.0"

  network_configuration {
    security_groups = [aws_security_group.nsg_task.id, aws_security_group.assets.id]
    subnets         = module.vpc.private_subnets
  }

  service_registries {
    registry_arn = aws_service_discovery_service.assets.arn
  }

  capacity_provider_strategy {
    capacity_provider  = "FARGATE"
    weight = 1
    base = 3
  }

  capacity_provider_strategy {
    capacity_provider  = "FARGATE_SPOT"
    weight = 4
  }
}

resource "aws_security_group" "assets" {
  name_prefix = "${var.environment_name}-assets"
  vpc_id      = module.vpc.vpc_id

  description = "Marker SG for assets service"
}

resource "aws_service_discovery_service" "assets" {
  name  = "assets"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.sd.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}