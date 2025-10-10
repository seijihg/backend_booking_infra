# Variables for ECS Worker Module - Cost-optimized configuration

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
}

# Cluster Configuration
variable "ecs_cluster_id" {
  description = "ECS cluster ID where workers will run"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for CloudWatch metrics"
  type        = string
}

# Container Configuration
variable "ecr_repository_url" {
  description = "ECR repository URL for the Docker image"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

# Worker Configuration
variable "worker_count" {
  description = "Fixed number of worker tasks (no auto-scaling)"
  type        = number
  default     = 1  # Minimal for cost saving
}

variable "worker_cpu" {
  description = "CPU units for worker tasks (256 = 0.25 vCPU)"
  type        = string
  default     = "256"  # Minimum Fargate CPU
}

variable "worker_memory" {
  description = "Memory for worker tasks in MB"
  type        = string
  default     = "512"  # Minimum Fargate memory
}

variable "worker_command" {
  description = "Command to run Dramatiq workers (replaces the CMD, entrypoint.sh will exec this)"
  type        = list(string)
  default     = ["python", "manage.py", "rundramatiq"]
}

variable "worker_concurrency" {
  description = "Number of concurrent threads per worker"
  type        = number
  default     = 2  # Low concurrency for minimal resources
}

variable "worker_queues" {
  description = "Comma-separated list of queue names to process"
  type        = string
  default     = "default,notifications,bookings"
}

# Network Configuration
variable "private_subnet_ids" {
  description = "Private subnet IDs where workers will run"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for worker tasks"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks (needed if in public subnet for internet access)"
  type        = bool
  default     = false
}

# Secrets Configuration
variable "secrets_from_parameter_store" {
  description = "Secrets to pull from AWS Parameter Store"
  type = list(object({
    name      = string
    valueFrom = string
  }))
}

variable "additional_environment_variables" {
  description = "Additional environment variables for the worker container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Cost Optimization
variable "use_fargate_spot" {
  description = "Use Fargate Spot for 70% cost savings (tasks may be interrupted)"
  type        = bool
  default     = true  # Enable by default for workers
}

variable "placement_constraints" {
  description = "Placement constraints for ECS tasks"
  type = list(object({
    type       = string
    expression = string
  }))
  default = []
}

# S3 Access (Optional)
variable "enable_s3_access" {
  description = "Enable S3 access for workers (for file processing)"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket name for worker access"
  type        = string
  default     = ""
}

# Monitoring
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7  # Minimal retention for cost saving
}

variable "enable_monitoring_alarms" {
  description = "Enable CloudWatch alarms (no auto-scaling, just notifications)"
  type        = bool
  default     = false  # Disabled by default for cost saving
}

variable "alarm_notification_arns" {
  description = "SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}