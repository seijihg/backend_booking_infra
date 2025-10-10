# ECS Worker Module - Minimal cost configuration for Dramatiq background workers

# Task Execution Role (allows ECS to pull images and write logs)
resource "aws_iam_role" "worker_execution_role" {
  name = "${var.app_name}-${var.environment}-worker-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach managed policy for ECR and CloudWatch Logs
resource "aws_iam_role_policy_attachment" "worker_execution_role_policy" {
  role       = aws_iam_role.worker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Policy for SSM Parameter Store access (execution role needs this to retrieve secrets at startup)
resource "aws_iam_role_policy" "worker_execution_ssm" {
  name = "${var.app_name}-${var.environment}-worker-execution-ssm"
  role = aws_iam_role.worker_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/backend-booking/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Task Role (for application permissions)
resource "aws_iam_role" "worker_task_role" {
  name = "${var.app_name}-${var.environment}-worker-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Policy for Parameter Store access (to read secrets)
resource "aws_iam_role_policy" "worker_parameter_store" {
  name = "${var.app_name}-${var.environment}-worker-params"
  role = aws_iam_role.worker_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/backend-booking/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Policy for S3 access (if workers need to process files)
resource "aws_iam_role_policy" "worker_s3_access" {
  count = var.enable_s3_access ? 1 : 0
  name  = "${var.app_name}-${var.environment}-worker-s3"
  role  = aws_iam_role.worker_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      }
    ]
  })
}

# CloudWatch Log Group for Workers
resource "aws_cloudwatch_log_group" "worker_logs" {
  name              = "/ecs/${var.app_name}-${var.environment}-worker"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Task Definition for Workers
resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.app_name}-${var.environment}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  # Minimal resources for cost optimization
  cpu    = var.worker_cpu    # Default: 256 (0.25 vCPU)
  memory = var.worker_memory  # Default: 512 MB

  execution_role_arn = aws_iam_role.worker_execution_role.arn
  task_role_arn      = aws_iam_role.worker_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "${var.app_name}-worker"
      image = "${var.ecr_repository_url}:${var.image_tag}"

      # The entrypoint.sh script will run health checks and migrations,
      # then exec our command (rundramatiq) instead of gunicorn
      # Keep the default entrypoint: ENTRYPOINT ["/app/entrypoint.sh"]
      # Just override the CMD
      command = var.worker_command

      # Environment variables
      environment = concat(
        [
          {
            name  = "WORKER_CONCURRENCY"
            value = tostring(var.worker_concurrency)
          },
          {
            name  = "WORKER_QUEUES"
            value = var.worker_queues
          },
          {
            name  = "DRAMATIQ_BROKER"
            value = "redis"
          }
        ],
        var.additional_environment_variables
      )

      # Secrets from Parameter Store (same as web tasks)
      secrets = var.secrets_from_parameter_store

      # Logging
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "worker"
        }
      }

      # Health check for worker process
      healthCheck = {
        command     = ["CMD-SHELL", "echo ok"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      # Resource limits (prevent runaway processes)
      ulimits = [
        {
          name      = "nofile"
          softLimit = 1024
          hardLimit = 4096
        }
      ]

      # Graceful shutdown
      stopTimeout = 120  # Give workers 2 minutes to finish current tasks
    }
  ])

  tags = var.tags
}

# ECS Service for Workers (no auto-scaling, no load balancer)
resource "aws_ecs_service" "worker" {
  name            = "${var.app_name}-${var.environment}-worker"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.worker.arn

  # Fixed number of workers (no auto-scaling for cost saving)
  desired_count = var.worker_count  # Default: 1

  launch_type = var.use_fargate_spot ? null : "FARGATE"

  # Use Fargate Spot for 70% cost savings (if enabled)
  dynamic "capacity_provider_strategy" {
    for_each = var.use_fargate_spot ? [1] : []
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 100
      base              = 0
    }
  }

  network_configuration {
    security_groups  = var.security_group_ids
    subnets          = var.private_subnet_ids
    # If using public subnets (for internet access), assign public IP
    # Otherwise workers can't reach external APIs like Twilio
    assign_public_ip = var.assign_public_ip
  }

  # Deployment configuration
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Circuit breaker for automatic rollback
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Placement constraints for better cost optimization
  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  tags = var.tags

  # Ignore task definition changes from external sources
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# CloudWatch Alarms (optional, for monitoring without auto-scaling)
resource "aws_cloudwatch_metric_alarm" "worker_cpu_high" {
  count = var.enable_monitoring_alarms ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-worker-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Triggers when worker CPU exceeds 80%"

  dimensions = {
    ServiceName = aws_ecs_service.worker.name
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = var.alarm_notification_arns

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "worker_memory_high" {
  count = var.enable_monitoring_alarms ? 1 : 0

  alarm_name          = "${var.app_name}-${var.environment}-worker-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Triggers when worker memory exceeds 80%"

  dimensions = {
    ServiceName = aws_ecs_service.worker.name
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = var.alarm_notification_arns

  tags = var.tags
}