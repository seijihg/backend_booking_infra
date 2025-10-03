# ECS Task Definition Module Variables

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
  default     = "eu-west-2"
}

# Container Configuration
variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Docker image URL with tag"
  type        = string
  # Example: "123456789012.dkr.ecr.eu-west-2.amazonaws.com/backend-booking-dev:latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8000
}

# Task Resources
variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Memory for the task in MB (512, 1024, 2048, 4096, 8192, etc.)"
  type        = string
  default     = "1024"
}

# IAM Roles
variable "execution_role_arn" {
  description = "ARN of the task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role"
  type        = string
}

# CloudWatch Logs
variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

# Django Configuration

variable "allowed_hosts" {
  description = "Django ALLOWED_HOSTS setting"
  type        = string
  default     = "*"
}

variable "debug_mode" {
  description = "Enable Django debug mode"
  type        = bool
  default     = false
}

# Optional Services Configuration
variable "enable_twilio" {
  description = "Enable Twilio SMS configuration"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket name for static files (optional)"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (optional)"
  type        = string
  default     = ""
}

# Additional Environment Variables
variable "environment_variables" {
  description = "Additional environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secrets_from_parameter_store" {
  description = "Additional secrets to pull from Parameter Store"
  type        = map(string)
  default     = {}
  # Example: { "API_KEY" = "/backend-booking/dev/app/api-key" }
}

# Health Check Configuration - REMOVED
# Container-level health checks have been removed from this module.
# Use ALB target group health checks instead, which are more reliable
# and don't add overhead to the container.
# See the ALB module for health check configuration.

# Container Timeouts
variable "stop_timeout" {
  description = "Time to wait for container to stop gracefully"
  type        = number
  default     = 30
}

variable "start_timeout" {
  description = "Time to wait for container to start"
  type        = number
  default     = 120
}

# Security Configuration
variable "readonly_root_filesystem" {
  description = "Make root filesystem read-only"
  type        = bool
  default     = false
}

variable "container_user" {
  description = "User to run the container as"
  type        = string
  default     = null
}

# Linux Parameters
variable "enable_linux_parameters" {
  description = "Enable Linux parameters configuration"
  type        = bool
  default     = false
}

variable "linux_capabilities_add" {
  description = "Linux capabilities to add"
  type        = list(string)
  default     = []
}

variable "linux_capabilities_drop" {
  description = "Linux capabilities to drop"
  type        = list(string)
  default     = []
}

variable "init_process_enabled" {
  description = "Run an init process inside the container"
  type        = bool
  default     = false
}

# Container Overrides
variable "container_command" {
  description = "Command to override default container command"
  type        = list(string)
  default     = null
}

variable "container_entry_point" {
  description = "Entry point to override default container entry point"
  type        = list(string)
  default     = null
}

variable "working_directory" {
  description = "Working directory for the container"
  type        = string
  default     = null
}

# Advanced Configuration
variable "ulimits" {
  description = "Container ulimits"
  type = list(object({
    name      = string
    hardLimit = number
    softLimit = number
  }))
  default = []
}

variable "mount_points" {
  description = "Container mount points"
  type = list(object({
    sourceVolume  = string
    containerPath = string
    readOnly      = bool
  }))
  default = []
}

variable "volumes_from" {
  description = "Volumes to mount from other containers"
  type = list(object({
    sourceContainer = string
    readOnly        = bool
  }))
  default = []
}

variable "volumes" {
  description = "Task volumes configuration"
  type = list(object({
    name = string
    efs_volume_configuration = optional(object({
      file_system_id          = string
      root_directory          = optional(string)
      transit_encryption      = optional(string)
      transit_encryption_port = optional(number)
      authorization_config = optional(object({
        access_point_id = optional(string)
        iam             = optional(string)
      }))
    }))
  }))
  default = []
}

variable "container_depends_on" {
  description = "Container dependencies"
  type = list(object({
    containerName = string
    condition     = string
  }))
  default = []
}

# Runtime Platform
variable "operating_system_family" {
  description = "Operating system family for the task"
  type        = string
  default     = "LINUX"
}

variable "cpu_architecture" {
  description = "CPU architecture (X86_64 or ARM64)"
  type        = string
  default     = "X86_64"
}

# Tags
variable "tags" {
  description = "Tags to apply to the task definition"
  type        = map(string)
  default     = {}
}
