# ECS Task Definition Module for Django Application

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.environment}"
  network_mode             = "awsvpc"  # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn           = var.task_role_arn

  # Container Definition
  container_definitions = jsonencode([
    {
      name  = var.container_name
      image = var.container_image

      # Port Mappings
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      # Environment Variables (non-sensitive)
      environment = concat(
        [
          {
            name  = "DJANGO_SETTINGS_MODULE"
            value = var.django_settings_module
          },
          {
            name  = "ENVIRONMENT"
            value = var.environment
          },
          {
            name  = "PORT"
            value = tostring(var.container_port)
          },
          {
            name  = "ALLOWED_HOSTS"
            value = var.allowed_hosts
          },
          {
            name  = "DEBUG"
            value = var.debug_mode ? "True" : "False"
          },
          {
            name  = "PYTHONUNBUFFERED"
            value = "1"
          },
          {
            name  = "DATABASE_ENGINE"
            value = "django.db.backends.postgresql"
          },
          {
            name  = "DATABASE_PORT"
            value = "5432"
          },
          {
            name  = "REDIS_PORT"
            value = "6379"
          }
        ],
        # Additional custom environment variables
        [for k, v in var.environment_variables : {
          name  = k
          value = v
        }]
      )

      # Secrets from Parameter Store (sensitive data)
      secrets = concat(
        [
          {
            name      = "DJANGO_SECRET_KEY"
            valueFrom = "/backend-booking/${var.environment}/app/django-secret-key"
          },
          {
            name      = "DATABASE_PASSWORD"
            valueFrom = "/backend-booking/${var.environment}/database/password"
          },
          {
            name      = "DATABASE_HOST"
            valueFrom = "/backend-booking/${var.environment}/database/host"
          },
          {
            name      = "DATABASE_NAME"
            valueFrom = "/backend-booking/${var.environment}/database/name"
          },
          {
            name      = "DATABASE_USER"
            valueFrom = "/backend-booking/${var.environment}/database/username"
          },
          {
            name      = "REDIS_HOST"
            valueFrom = "/backend-booking/${var.environment}/redis/host"
          }
        ],
        # Optional Twilio configuration
        var.enable_twilio ? [
          {
            name      = "TWILIO_ACCOUNT_SID"
            valueFrom = "/backend-booking/${var.environment}/third-party/twilio-account-sid"
          },
          {
            name      = "TWILIO_AUTH_TOKEN"
            valueFrom = "/backend-booking/${var.environment}/third-party/twilio-auth-token"
          },
          {
            name      = "TWILIO_PHONE_NUMBER"
            valueFrom = "/backend-booking/${var.environment}/third-party/twilio-phone-number"
          }
        ] : [],
        # Optional S3 configuration
        var.s3_bucket_name != "" ? [
          {
            name      = "AWS_STORAGE_BUCKET_NAME"
            valueFrom = "/backend-booking/${var.environment}/aws/s3-bucket-name"
          }
        ] : [],
        # Optional CloudFront configuration
        var.cloudfront_distribution_id != "" ? [
          {
            name      = "AWS_CLOUDFRONT_DISTRIBUTION_ID"
            valueFrom = "/backend-booking/${var.environment}/aws/cloudfront-distribution-id"
          }
        ] : [],
        # Additional custom secrets
        [for k, v in var.secrets_from_parameter_store : {
          name      = k
          valueFrom = v
        }]
      )

      # CloudWatch Logs Configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.container_name
        }
      }

      # Health Check (container level)
      healthCheck = var.enable_health_check ? {
        command     = var.health_check_command
        interval    = var.health_check_interval
        timeout     = var.health_check_timeout
        retries     = var.health_check_retries
        startPeriod = var.health_check_start_period
      } : null

      # Resource Limits (optional)
      ulimits = var.ulimits

      # Mount Points (optional)
      mountPoints = var.mount_points

      # Volumes From (optional)
      volumesFrom = var.volumes_from

      # Essential - if this container fails, stop the whole task
      essential = true

      # Stop timeout for graceful shutdown
      stopTimeout = var.stop_timeout

      # Start timeout
      startTimeout = var.start_timeout

      # Readonly root filesystem (security best practice)
      readonlyRootFilesystem = var.readonly_root_filesystem

      # Linux parameters (optional)
      linuxParameters = var.enable_linux_parameters ? {
        capabilities = {
          add  = var.linux_capabilities_add
          drop = var.linux_capabilities_drop
        }
        initProcessEnabled = var.init_process_enabled
      } : null

      # Command override (optional)
      command = var.container_command

      # Entry point override (optional)
      entryPoint = var.container_entry_point

      # Working directory
      workingDirectory = var.working_directory

      # User to run the container as
      user = var.container_user

      # Dependency configuration
      dependsOn = var.container_depends_on
    }
  ])

  # Volume configuration (optional)
  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", null) != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", "/")
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", "ENABLED")
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
          
          dynamic "authorization_config" {
            for_each = lookup(efs_volume_configuration.value, "authorization_config", null) != null ? [efs_volume_configuration.value.authorization_config] : []
            content {
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
              iam             = lookup(authorization_config.value, "iam", null)
            }
          }
        }
      }
    }
  }

  # Runtime platform (for ARM64 if needed)
  runtime_platform {
    operating_system_family = var.operating_system_family
    cpu_architecture       = var.cpu_architecture
  }

  # Tags
  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-task-definition"
      Environment = var.environment
      Application = var.app_name
    }
  )
}