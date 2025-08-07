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
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
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
  name     = "${var.app_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.networking.vpc_id
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

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  # General Configuration
  app_name    = var.app_name
  environment = var.environment
  aws_region  = var.aws_region
  tags        = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }

  # Networking
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = [module.networking.private_subnet_id]
  alb_security_group_id = aws_security_group.alb.id

  # Container Configuration
  ecr_repository_url = aws_ecr_repository.app.repository_url
  image_tag         = var.ecs_image_tag
  task_cpu          = var.ecs_task_cpu
  task_memory       = var.ecs_task_memory
  container_port    = var.ecs_container_port

  # Application Configuration
  allowed_hosts              = var.allowed_hosts
  s3_bucket_name            = "" # Will be added when S3 module is implemented
  s3_bucket_arn             = "arn:aws:s3:::placeholder/*" # Placeholder
  cloudfront_distribution_id = "" # Will be added when CloudFront is implemented
  redis_url                 = "redis://placeholder:6379" # Will be updated when Redis is implemented

  # Database Configuration (placeholders for now)
  database_host = "placeholder-db-host"
  database_name = var.database_name

  # Seed Data Configuration
  seed_data           = var.seed_data
  seed_owner_password = var.seed_owner_password

  # Note: Secrets are managed via Parameter Store
  # The ECS module constructs the parameter ARNs internally
  # based on the pattern: /backend-booking/{environment}/{service}/{parameter}
  # Seed password is stored as: /backend-booking/{environment}/seed-data/owner-default-password

  # ECS Service Configuration
  desired_count    = var.ecs_desired_count
  target_group_arn = aws_lb_target_group.app.arn

  # Auto Scaling
  min_capacity        = var.ecs_min_capacity
  max_capacity        = var.ecs_max_capacity
  cpu_target_value    = var.ecs_cpu_target
  memory_target_value = var.ecs_memory_target

  # Monitoring
  alarm_actions      = [] # Will add SNS topic later
  log_retention_days = var.log_retention_days

  # Development specific settings
  enable_fargate_spot = var.environment == "dev" ? true : false
  fargate_spot_weight = 4
  enable_ecs_exec     = var.environment == "dev" ? true : false
}