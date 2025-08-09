# Development Environment Main Configuration

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}

# ECR Repository for Docker Images
resource "aws_ecr_repository" "app" {
  name                 = "${var.app_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-ecr"
    Environment = var.environment
  }
}

# ECR Lifecycle Policy to keep only last 10 images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Application Load Balancer Module
module "alb" {
  source = "../../modules/alb"

  app_name    = var.app_name
  environment = var.environment
  
  # Networking
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids  # Now using 2 AZs for ALB requirement
  security_group_id = aws_security_group.alb.id
  
  # Target configuration for ECS
  target_port     = 8000  # Django default port
  target_protocol = "HTTP"
  target_type     = "ip"  # Required for Fargate
  
  # Health check configuration
  health_check_path                = "/health/"
  health_check_interval            = 30
  health_check_timeout             = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2
  health_check_matcher             = "200"
  
  # Deregistration delay (shorter for dev)
  deregistration_delay = 15
  
  # SSL/TLS (disabled for dev - add certificate ARN for HTTPS)
  certificate_arn = ""  # var.certificate_arn when ready
  
  # Development settings
  enable_deletion_protection = false
  enable_access_logs        = false  # Save costs in dev
  enable_stickiness         = false
  
  # Monitoring (basic for dev)
  enable_alarms         = true
  alarm_actions        = []  # Add SNS topic when ready
  response_time_threshold = 3  # More lenient for dev
  error_rate_threshold    = 25  # More lenient for dev
  
  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
}

# ECS Cluster Module - Only creates the cluster infrastructure
# Task definitions and services will be created later when ECR images are ready
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  # General Configuration
  app_name    = var.app_name
  environment = var.environment
  aws_region  = var.aws_region
  vpc_id      = module.networking.vpc_id

  # Cluster Configuration
  enable_container_insights = true
  log_retention_days        = var.log_retention_days

  # Fargate Configuration
  enable_fargate_spot = var.environment == "dev" ? true : false
  fargate_weight      = 1
  fargate_base        = 1
  fargate_spot_weight = var.environment == "dev" ? 4 : 0

  # Service Discovery (optional - enable when needed)
  enable_service_discovery = false

  # S3 Configuration (will be provided when S3 module is ready)
  s3_bucket_arn = "" # Will be added when S3 module is implemented

  # Monitoring
  alarm_actions = [] # Will add SNS topic later

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
}

# ECS Task Definition Module - Defines how the Django container runs
module "app_task_definition" {
  source = "../../modules/ecs-task-definition"

  app_name    = var.app_name
  environment = var.environment
  aws_region  = var.aws_region
  
  # Container configuration
  container_name  = "${var.app_name}-app"
  container_image = "${aws_ecr_repository.app.repository_url}:latest"  # Using the latest image you pushed
  container_port  = 8000
  
  # Task resources (dev environment - minimal)
  task_cpu    = var.ecs_task_cpu
  task_memory = var.ecs_task_memory
  
  # IAM Roles from ECS cluster
  execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn     = module.ecs_cluster.task_role_arn
  
  # CloudWatch Logs
  log_group_name = module.ecs_cluster.log_group_name
  
  # Django configuration
  django_settings_module = "config.settings.production"  # Adjust based on your Django project
  allowed_hosts         = var.allowed_hosts
  debug_mode           = var.environment == "dev" ? true : false
  
  # Optional services (disabled for now)
  enable_twilio              = true  # Enable when Twilio is configured
  s3_bucket_name            = ""     # Will add when S3 module is ready
  cloudfront_distribution_id = ""     # Will add when CloudFront is ready
  
  # Additional environment variables if needed
  environment_variables = {
    "CORS_ALLOWED_ORIGINS" = "*"  # Adjust for production
    "USE_X_FORWARDED_HOST" = "True"
    "SECURE_PROXY_SSL_HEADER" = "HTTP_X_FORWARDED_PROTO,https"
  }
  
  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
}

# TODO: Next steps:
# 1. ECS Service module (to manage running tasks)
# 2. Auto-scaling policies
# 3. Worker tasks module (for Dramatiq background jobs)
