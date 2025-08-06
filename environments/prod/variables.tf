# Variables for Production Environment

variable "aws_region" {
  description = "AWS region for the production environment"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "backend-booking"
}

# Add more environment-specific variables as needed
# Examples:

# variable "instance_type" {
#   description = "EC2 instance type for ECS tasks"
#   type        = string
#   default     = "t3.large"
# }

# variable "db_instance_class" {
#   description = "RDS instance class"
#   type        = string
#   default     = "db.r6g.large"
# }

# variable "min_capacity" {
#   description = "Minimum number of ECS tasks"
#   type        = number
#   default     = 3
# }

# variable "max_capacity" {
#   description = "Maximum number of ECS tasks"
#   type        = number
#   default     = 10
# }

# variable "enable_multi_az" {
#   description = "Enable Multi-AZ for RDS"
#   type        = bool
#   default     = true
# }

# variable "backup_retention_period" {
#   description = "Number of days to retain RDS backups"
#   type        = number
#   default     = 30
# }