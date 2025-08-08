# CodePipeline Module Variables

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# GitHub Configuration
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "seijihg"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "backend_booking"
}

variable "github_branch" {
  description = "GitHub branch to track"
  type        = string
  default     = "main"
}

variable "github_token_parameter_name" {
  description = "Name of the Parameter Store parameter containing the GitHub token"
  type        = string
  default     = "/backend-booking/common/github-token"
}

# ECR Configuration
variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

# ECS Configuration
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service to deploy to"
  type        = string
  default     = ""  # Optional - only needed when service exists
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

# VPC Configuration (optional)
variable "enable_vpc_config" {
  description = "Enable VPC configuration for CodeBuild"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for CodeBuild (if VPC is enabled)"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for CodeBuild (if VPC is enabled)"
  type        = list(string)
  default     = []
}

# Build Configuration
variable "build_compute_type" {
  description = "Compute type for CodeBuild"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  # Options: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE
}

variable "build_image" {
  description = "Docker image for CodeBuild environment"
  type        = string
  default     = "aws/codebuild/standard:7.0"  # Ubuntu 22.04
}

variable "build_timeout" {
  description = "Build timeout in minutes"
  type        = number
  default     = 30
}

variable "queued_timeout" {
  description = "Queued timeout in minutes"
  type        = number
  default     = 60
}

variable "build_parameter_store_secrets" {
  description = "Parameter Store secrets to pass to build environment"
  type        = map(string)
  default     = {}
  # Example: { "DJANGO_SECRET_KEY" = "/backend-booking/dev/app/django-secret-key" }
}

# Deployment Configuration
variable "deployment_timeout" {
  description = "ECS deployment timeout in minutes"
  type        = number
  default     = 10
}

variable "require_manual_approval" {
  description = "Require manual approval before deployment"
  type        = bool
  default     = false
}

# Logging
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_s3_logs" {
  description = "Enable S3 logs for CodeBuild"
  type        = bool
  default     = false
}

variable "enable_build_badge" {
  description = "Enable build badge for CodeBuild project"
  type        = bool
  default     = true
}

# Notifications
variable "sns_topic_arn" {
  description = "SNS topic ARN for pipeline notifications"
  type        = string
  default     = ""
}

variable "enable_notifications" {
  description = "Enable pipeline notifications"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}