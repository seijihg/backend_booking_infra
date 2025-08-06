# Variables for Development Environment

variable "aws_region" {
  description = "AWS region for the development environment"
  type        = string
  default     = "eu-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
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
#   default     = "t3.small"
# }

# variable "db_instance_class" {
#   description = "RDS instance class"
#   type        = string
#   default     = "db.t3.micro"
# }

# variable "min_capacity" {
#   description = "Minimum number of ECS tasks"
#   type        = number
#   default     = 1
# }

# variable "max_capacity" {
#   description = "Maximum number of ECS tasks"
#   type        = number
#   default     = 3
# }