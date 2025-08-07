# General Variables
variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Networking Variables
variable "vpc_id" {
  description = "VPC ID where ECS tasks will run"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the Application Load Balancer"
  type        = string
}

# ECS Cluster Variables
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "enable_fargate_spot" {
  description = "Enable Fargate Spot for cost optimization"
  type        = bool
  default     = false
}

variable "fargate_weight" {
  description = "Weight for FARGATE capacity provider"
  type        = number
  default     = 1
}

variable "fargate_base" {
  description = "Base value for FARGATE capacity provider"
  type        = number
  default     = 1
}

variable "fargate_spot_weight" {
  description = "Weight for FARGATE_SPOT capacity provider"
  type        = number
  default     = 0
}

# Task Definition Variables
variable "ecr_repository_url" {
  description = "URL of the ECR repository containing the Docker image"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory for the task in MB (512, 1024, 2048, etc.)"
  type        = string
  default     = "1024"
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 8000
}

# Application Configuration
variable "allowed_hosts" {
  description = "Django ALLOWED_HOSTS setting"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for static files"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for IAM policies"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  type        = string
  default     = ""
}

variable "redis_url" {
  description = "Redis connection URL"
  type        = string
}

# Database Configuration
variable "database_host" {
  description = "Database host for PgBouncer"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

# Seed Data Configuration (non-sensitive)
variable "seed_data" {
  description = "Seed data configuration for initial setup (non-sensitive data)"
  type = object({
    salon = object({
      name        = string
      street      = string
      city        = string
      postal_code = string
    })
    owner = object({
      email      = string
      first_name = string
      last_name  = string
      full_name  = string
    })
  })
  default = null
}

# Seed Owner Password (separate for security)
variable "seed_owner_password" {
  description = "Seed owner default password"
  type        = string
  sensitive   = true
  default     = ""
}

# Note: Secrets are stored in AWS Systems Manager Parameter Store
# Parameters follow the pattern: /backend-booking/{environment}/{service}/{parameter}
# No need to pass ARNs as they are constructed within the module

# ECS Service Variables
variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "deployment_maximum_percent" {
  description = "Maximum percent of tasks during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 100
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 60
}

variable "enable_ecs_exec" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}

variable "enable_service_discovery" {
  description = "Enable service discovery"
  type        = bool
  default     = false
}

variable "service_discovery_arn" {
  description = "Service discovery registry ARN"
  type        = string
  default     = ""
}

# Auto Scaling Variables
variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for scaling"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target memory utilization percentage for scaling"
  type        = number
  default     = 80
}

variable "scale_in_cooldown" {
  description = "Cooldown period in seconds before scaling in"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown period in seconds before scaling out"
  type        = number
  default     = 60
}

variable "enable_request_count_scaling" {
  description = "Enable scaling based on ALB request count"
  type        = bool
  default     = false
}

variable "request_count_target" {
  description = "Target request count per task for scaling"
  type        = number
  default     = 1000
}

variable "alb_resource_label" {
  description = "ALB resource label for request count scaling"
  type        = string
  default     = ""
}

# EFS Variables (Optional)
variable "enable_efs" {
  description = "Enable EFS for persistent storage"
  type        = bool
  default     = false
}

variable "efs_file_system_id" {
  description = "EFS file system ID"
  type        = string
  default     = ""
}

variable "efs_access_point_id" {
  description = "EFS access point ID"
  type        = string
  default     = ""
}

# Logging Variables
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# Monitoring Variables
variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}