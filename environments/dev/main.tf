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

# TODO: Future modules to be added when ready:
# 1. ECS Task Definitions module (when ECR images are built)
# 2. ECS Services module (when ALB is fully configured)
# 3. Auto-scaling policies module
# 4. Worker tasks module (for Dramatiq background jobs)
