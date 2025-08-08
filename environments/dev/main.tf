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

# Placeholder for ALB Target Group (needed for ECS)
# This will be replaced when ALB module is implemented
resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health/"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.app_name}-${var.environment}-tg"
    Environment = var.environment
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
