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

# CodePipeline CI/CD Module - Automated deployment from GitHub
module "codepipeline" {
  source = "../../modules/codepipeline"

  app_name    = var.app_name
  environment = var.environment

  # GitHub Configuration - triggers on main branch
  github_owner  = var.github_owner
  github_repo   = var.github_repo
  github_branch = "main" # Triggers on merge to main
  # Note: GitHub connection now uses CodeStar Connections (v2) instead of OAuth token

  # ECR Configuration
  ecr_repository_url = aws_ecr_repository.app.repository_url

  # ECS Configuration
  ecs_cluster_name            = module.ecs_cluster.cluster_id
  ecs_service_name            = module.app_service.service_name
  container_name              = "${var.app_name}-app" # Must match task definition
  ecs_task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  ecs_task_role_arn           = module.ecs_cluster.task_role_arn

  # Build Configuration
  build_compute_type = "BUILD_GENERAL1_SMALL" # Sufficient for dev
  build_timeout      = 30
  enable_build_badge = true

  # Build environment secrets from Parameter Store
  # Note: Build process doesn't need Django secrets - they're injected at runtime by ECS
  build_parameter_store_secrets = {}

  # No manual approval for dev environment
  require_manual_approval = false
  deployment_timeout      = 10

  # Logging
  log_retention_days = var.log_retention_days

  # Notifications (optional - add SNS topic when ready)
  enable_notifications = false

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
    Purpose     = "CI/CD Pipeline"
  }

  # Ensure cluster and service exist before creating pipeline
  depends_on = [
    module.ecs_cluster,
    module.app_service
  ]
}

# Application Load Balancer Module
module "alb" {
  source = "../../modules/alb"

  app_name    = var.app_name
  environment = var.environment

  # Networking
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids # Now using 2 AZs for ALB requirement
  security_group_id = aws_security_group.alb.id

  # Target configuration for ECS
  target_port     = 8000 # Django default port
  target_protocol = "HTTP"
  target_type     = "ip" # Required for Fargate

  # Health check configuration
  health_check_path                = "/health/" # Django has a proper health check endpoint
  health_check_interval            = 30
  health_check_timeout             = 10 # Increased timeout for Django startup
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3     # More tolerance for unhealthy checks
  health_check_matcher             = "200" # Only accept 200 OK from health endpoint

  # Deregistration delay (shorter for dev)
  deregistration_delay = 15

  # SSL/TLS - Enable HTTPS with ACM certificate
  certificate_arn = aws_acm_certificate_validation.backend.certificate_arn

  # Development settings
  enable_deletion_protection = false
  enable_access_logs         = false # Save costs in dev
  enable_stickiness          = false

  # Monitoring (basic for dev)
  enable_alarms           = true
  alarm_actions           = [] # Add SNS topic when ready
  response_time_threshold = 3  # More lenient for dev
  error_rate_threshold    = 25 # More lenient for dev

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
  container_image = "${aws_ecr_repository.app.repository_url}:latest" # Using the latest image you pushed
  container_port  = 8000

  # Task resources (dev environment - minimal)
  task_cpu    = var.ecs_task_cpu
  task_memory = var.ecs_task_memory

  # IAM Roles from ECS cluster
  execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn      = module.ecs_cluster.task_role_arn

  # CloudWatch Logs
  log_group_name = module.ecs_cluster.log_group_name

  # Django configuration
  allowed_hosts = var.allowed_hosts
  debug_mode    = var.environment == "dev" ? true : false

  # Optional services (disabled for now)
  enable_twilio              = true # Enable when Twilio is configured
  s3_bucket_name             = ""   # Will add when S3 module is ready
  cloudfront_distribution_id = ""   # Will add when CloudFront is ready

  # Additional environment variables if needed
  environment_variables = {
    "USE_X_FORWARDED_HOST"    = "True"
    "SECURE_PROXY_SSL_HEADER" = "HTTP_X_FORWARDED_PROTO,https"
    # Seed data for initial setup
    "SEED_SALON_NAME"        = "USA Nails Berkhamsted"
    "SEED_SALON_STREET"      = "5 London Road"
    "SEED_SALON_CITY"        = "Berkhamsted"
    "SEED_SALON_POSTAL_CODE" = "HP4 2HS"
    "SEED_OWNER_EMAIL"       = "seiji@o2.pl"
    "SEED_OWNER_FIRST_NAME"  = "Le"
    "SEED_OWNER_LAST_NAME"   = "Ngo"
    "SEED_OWNER_FULL_NAME"   = "Le Hoang Ngo"
  }

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
}

# VPC Endpoints Module - Private connectivity to AWS services (no NAT Gateway needed)
module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"

  vpc_id      = module.networking.vpc_id
  vpc_cidr    = module.networking.vpc_cidr
  app_name    = var.app_name
  environment = var.environment
  aws_region  = var.aws_region

  # Subnets and route tables for endpoints
  private_subnet_ids      = module.networking.private_subnet_ids
  private_route_table_ids = [module.networking.private_route_table_id]

  # Security groups that need access to endpoints
  security_group_ids = [
    aws_security_group.ecs_tasks.id
  ]

  # Enable all required endpoints for ECS
  enable_ssm_endpoints = true # For Parameter Store
  enable_ecr_endpoints = true # For Docker images
  enable_s3_endpoint   = true # For ECR layers (free!)
  enable_logs_endpoint = true # For CloudWatch logs

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
    Purpose     = "Private AWS service access"
  }
}

# ECS Service Module - Manages running tasks with auto-scaling and load balancer integration
module "app_service" {
  source = "../../modules/ecs-service"

  app_name    = var.app_name
  environment = var.environment

  # Cluster and Task Definition
  cluster_id          = module.ecs_cluster.cluster_id
  task_definition_arn = module.app_task_definition.task_definition_arn

  # Service Configuration
  service_name     = "${var.app_name}-${var.environment}-app"
  desired_count    = var.environment == "dev" ? 1 : 2
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  # Network Configuration - Back to private subnets with VPC endpoints
  vpc_id             = module.networking.vpc_id
  subnet_ids         = [module.networking.private_subnet_id] # Private subnet (secure)
  security_group_ids = [aws_security_group.ecs_tasks.id]
  assign_public_ip   = false # No public IP needed with VPC endpoints

  # Load Balancer Integration
  enable_load_balancer = true
  target_group_arn     = module.alb.target_group_arn
  container_name       = module.app_task_definition.container_name
  container_port       = module.app_task_definition.container_port

  # Auto-scaling Configuration (minimal for dev)
  enable_autoscaling = var.environment == "dev" ? false : true
  min_capacity       = var.environment == "dev" ? 1 : 2
  max_capacity       = var.environment == "dev" ? 2 : 10

  # CPU and Memory thresholds
  cpu_scale_up_threshold      = 70
  cpu_scale_down_threshold    = 30
  memory_scale_up_threshold   = 70
  memory_scale_down_threshold = 30

  # Deployment Configuration
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = var.environment == "dev" ? 0 : 100
  health_check_grace_period_seconds  = 360

  # Circuit Breaker - automatic rollback on failure
  enable_deployment_circuit_breaker = true
  enable_deployment_rollback        = true

  # Enable ECS Exec for debugging (dev only)
  enable_execute_command = var.environment == "dev" ? true : false

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }

  # Ensure VPC endpoints are created before the service
  depends_on = [module.vpc_endpoints]
}


# ElastiCache Redis Module - Session storage and message broker
module "redis" {
  source = "../../modules/elasticache"

  # Required configuration
  app_name           = var.app_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  subnet_ids         = [module.networking.private_subnet_id]
  security_group_ids = [aws_security_group.redis.id]

  # Optional: Override defaults for production
  # node_type                = "cache.t3.small"  # Upgrade for production
  # num_cache_nodes          = 2                 # Add replica for HA
  # multi_az_enabled         = true              # Enable for production
  # snapshot_retention_limit = 5                 # Enable backups for production
  # enable_auth_token        = true              # Enable for production security
  # auth_token               = var.redis_auth_token

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
    Purpose     = "Session storage and message broker"
  }
}

# Dramatiq Worker Module - Background job processing
module "dramatiq_worker" {
  source = "../../modules/ecs-worker"

  # Basic Configuration
  app_name     = var.app_name
  environment  = var.environment
  aws_region   = var.aws_region

  # ECS Cluster
  ecs_cluster_id   = module.ecs_cluster.cluster_id
  ecs_cluster_name = module.ecs_cluster.cluster_name

  # Container - Using same image as web tasks
  ecr_repository_url = aws_ecr_repository.app.repository_url
  image_tag          = "latest"

  # Worker Configuration (minimal for cost optimization)
  worker_count       = var.worker_count
  worker_cpu         = var.worker_cpu
  worker_memory      = var.worker_memory
  worker_concurrency = var.worker_concurrency
  worker_queues      = var.worker_queues

  # Django settings (removed - not a module variable)

  # Network - Using public subnet for internet access (Twilio API)
  # TODO: Use private subnet + NAT Gateway for production
  private_subnet_ids = module.networking.public_subnet_ids  # Using public for dev (workers need internet)
  security_group_ids = [aws_security_group.ecs_tasks.id]
  assign_public_ip   = true  # Required when using public subnets

  # Secrets - Same as web tasks (from Parameter Store)
  secrets_from_parameter_store = [
    {
      name      = "DJANGO_SECRET_KEY"
      valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/app/django-secret-key"
    },
    {
      name      = "DATABASE_URL"
      valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/database/url"
    },
    {
      name      = "REDIS_URL"
      valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/redis/url"
    },
    {
      name      = "ALLOWED_HOSTS"
      valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/backend-booking/${var.environment}/app/allowed-hosts"
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
    }
  ]

  # Additional environment variables (workers don't need proxy headers)
  additional_environment_variables = []

  # Cost Optimization
  use_fargate_spot   = true  # 70% cost savings for dev
  log_retention_days = var.log_retention_days

  # Monitoring (disabled for dev to save costs)
  enable_monitoring_alarms = false

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
    Purpose     = "Background job processing"
  }

  # Ensure cluster and Redis are ready before creating workers
  depends_on = [
    module.ecs_cluster,
    module.redis,
    module.vpc_endpoints
  ]
}

# TODO: Next steps:
# 1. S3 module for static files
# 2. CloudFront CDN module
