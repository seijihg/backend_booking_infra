# Task Definition for Django Application
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = "${var.ecr_repository_url}:${var.image_tag}"

      cpu    = var.task_cpu
      memory = var.task_memory

      essential = true

      # Environment variables
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "ALLOWED_HOSTS"
          value = var.allowed_hosts
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "AWS_S3_BUCKET_NAME"
          value = var.s3_bucket_name
        },
        {
          name  = "AWS_CLOUDFRONT_DISTRIBUTION_ID"
          value = var.cloudfront_distribution_id
        },
        {
          name  = "REDIS_URL"
          value = var.redis_url
        }
      ]

      # Secrets from AWS Secrets Manager
      secrets = [
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = "${var.django_secret_arn}:secret_key::"
        },
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.database_secret_arn}:connection_string::"
        },
        {
          name      = "SENTRY_DSN"
          valueFrom = "${var.monitoring_secret_arn}:sentry_dsn::"
        },
        {
          name      = "NEW_RELIC_LICENSE_KEY"
          valueFrom = "${var.monitoring_secret_arn}:new_relic_key::"
        },
        {
          name      = "TWILIO_ACCOUNT_SID"
          valueFrom = "${var.twilio_secret_arn}:account_sid::"
        },
        {
          name      = "TWILIO_AUTH_TOKEN"
          valueFrom = "${var.twilio_secret_arn}:auth_token::"
        }
      ]

      # Port mappings
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      # Health check
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      # CloudWatch Logs
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "django"
        }
      }

      # Resource limits
      ulimits = [
        {
          name      = "nofile"
          softLimit = 65536
          hardLimit = 65536
        }
      ]

      # Mount points for EFS if needed
      mountPoints = var.enable_efs ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = "/app/media"
          readOnly      = false
        }
      ] : []

      # Stop timeout for graceful shutdown
      stopTimeout = 30
    },

    # Sidecar container for PgBouncer (connection pooling)
    {
      name  = "pgbouncer"
      image = "edoburu/pgbouncer:latest"

      cpu    = 128
      memory = 256

      essential = false

      environment = [
        {
          name  = "DATABASES_HOST"
          value = var.database_host
        },
        {
          name  = "DATABASES_PORT"
          value = "5432"
        },
        {
          name  = "DATABASES_DBNAME"
          value = var.database_name
        },
        {
          name  = "POOL_MODE"
          value = "transaction"
        },
        {
          name  = "MAX_CLIENT_CONN"
          value = "1000"
        },
        {
          name  = "DEFAULT_POOL_SIZE"
          value = "25"
        }
      ]

      secrets = [
        {
          name      = "DATABASES_USER"
          valueFrom = "${var.database_secret_arn}:username::"
        },
        {
          name      = "DATABASES_PASSWORD"
          valueFrom = "${var.database_secret_arn}:password::"
        }
      ]

      portMappings = [
        {
          containerPort = 6432
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "pgbouncer"
        }
      }
    }
  ])

  # EFS Volume configuration (optional)
  dynamic "volume" {
    for_each = var.enable_efs ? [1] : []
    content {
      name = "efs-storage"

      efs_volume_configuration {
        file_system_id     = var.efs_file_system_id
        root_directory     = "/media"
        transit_encryption = "ENABLED"

        authorization_config {
          access_point_id = var.efs_access_point_id
          iam             = "ENABLED"
        }
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-task-definition"
      Environment = var.environment
    }
  )
}

# Task Definition for Database Migrations (One-off tasks)
resource "aws_ecs_task_definition" "migrate" {
  family                   = "${var.app_name}-${var.environment}-migrate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "${var.app_name}-migrate"
      image = "${var.ecr_repository_url}:${var.image_tag}"

      # Override command to run migrations
      command = ["python", "manage.py", "migrate", "--noinput"]

      essential = true

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        }
      ]

      secrets = [
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = "${var.django_secret_arn}:secret_key::"
        },
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.database_secret_arn}:connection_string::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "migrate"
        }
      }
    }
  ])

  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-migrate-task"
      Environment = var.environment
    }
  )
}