# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Task Definition for Django Application
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = "${var.ecr_repository_url}:${var.image_tag}"

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
        },
        {
          name  = "SEED_SALON_NAME"
          value = var.seed_data != null ? var.seed_data.salon.name : ""
        },
        {
          name  = "SEED_SALON_STREET"
          value = var.seed_data != null ? var.seed_data.salon.street : ""
        },
        {
          name  = "SEED_SALON_CITY"
          value = var.seed_data != null ? var.seed_data.salon.city : ""
        },
        {
          name  = "SEED_SALON_POSTAL_CODE"
          value = var.seed_data != null ? var.seed_data.salon.postal_code : ""
        },
        {
          name  = "SEED_OWNER_EMAIL"
          value = var.seed_data != null ? var.seed_data.owner.email : ""
        },
        {
          name  = "SEED_OWNER_FIRST_NAME"
          value = var.seed_data != null ? var.seed_data.owner.first_name : ""
        },
        {
          name  = "SEED_OWNER_LAST_NAME"
          value = var.seed_data != null ? var.seed_data.owner.last_name : ""
        },
        {
          name  = "SEED_OWNER_FULL_NAME"
          value = var.seed_data != null ? var.seed_data.owner.full_name : ""
        }
      ]

      # Secrets from AWS Systems Manager Parameter Store
      secrets = [
        {
          name      = "DJANGO_SECRET_KEY"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/app/django-secret-key"
        },
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/database/password"
        },
        {
          name      = "DATABASE_HOST"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/database/host"
        },
        {
          name      = "DATABASE_NAME"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/database/name"
        },
        {
          name      = "DATABASE_USER"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/database/username"
        },
        {
          name      = "TWILIO_ACCOUNT_SID"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/third-party/twilio-account-sid"
        },
        {
          name      = "TWILIO_AUTH_TOKEN"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/third-party/twilio-auth-token"
        },
        {
          name      = "TWILIO_PHONE_NUMBER"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/third-party/twilio-phone-number"
        },
        {
          name      = "SEED_OWNER_DEFAULT_PASSWORD"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/seed-data/owner-default-password"
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
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/database/username"
        },
        {
          name      = "DATABASES_PASSWORD"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/database/password"
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
