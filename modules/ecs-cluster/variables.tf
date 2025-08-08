# ECS Cluster Module Variables

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

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

# Cluster Configuration
variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Fargate Configuration
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
  description = "Base tasks for FARGATE capacity provider"
  type        = number
  default     = 1
}

variable "fargate_spot_weight" {
  description = "Weight for FARGATE_SPOT capacity provider"
  type        = number
  default     = 2
}

# Service Discovery
variable "enable_service_discovery" {
  description = "Enable service discovery for the cluster"
  type        = bool
  default     = false
}

# S3 Configuration (Optional)
variable "s3_bucket_arn" {
  description = "ARN of S3 bucket for application storage (optional)"
  type        = string
  default     = ""
}

# Monitoring
variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}