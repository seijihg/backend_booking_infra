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

variable "domain_name" {
  description = "The domain name for Route53 hosted zone"
  type        = string
  default     = "lichnails.co.uk"
}

# ECS Configuration Variables
variable "ecs_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = string
  default     = "512"
}

variable "ecs_container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 8000
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 3
}

variable "ecs_cpu_target" {
  description = "Target CPU utilization for auto-scaling"
  type        = number
  default     = 70
}

variable "ecs_memory_target" {
  description = "Target memory utilization for auto-scaling"
  type        = number
  default     = 80
}

# Application Configuration
variable "allowed_hosts" {
  description = "Django ALLOWED_HOSTS setting"
  type        = string
  default     = "*"
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "backend_booking_dev"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Secrets Configuration
variable "django_secret_key" {
  description = "Django secret key (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "database_password" {
  description = "Database password (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "twilio_account_sid" {
  description = "Twilio Account SID"
  type        = string
  default     = ""
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token (sensitive)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "twilio_phone_number" {
  description = "Twilio phone number for sending SMS"
  type        = string
  default     = "+447723468188"
}

# GitHub Configuration for CodePipeline
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

# Note: GitHub token is stored in AWS Parameter Store at /backend-booking/common/github-token
# The CodePipeline module retrieves it directly from Parameter Store
# No need to pass it as a Terraform variable for security reasons

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
  default = {
    salon = {
      name        = "USA Nails"
      street      = "5 London Road"
      city        = "Berkhamsted"
      postal_code = "HP4 2BU"
    }
    owner = {
      email      = "seiji@o2.pl"
      first_name = "Le"
      last_name  = "Ngo"
      full_name  = "Le Ngo"
    }
  }
}

# Seed Owner Password (separate for easy override)
variable "seed_owner_password" {
  description = "Seed owner default password - override this in terraform.tfvars"
  type        = string
  sensitive   = true
  default     = ""
}

# Additional variables for Parameter Store
variable "database_host" {
  description = "Database host endpoint"
  type        = string
  default     = ""
}

variable "redis_host" {
  description = "Redis host endpoint"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "S3 bucket name for static files"
  type        = string
  default     = ""
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  type        = string
  default     = ""
}

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
