# Provider Configuration for Production Environment
# Uses AWS Provider 6.0 with enhanced features and performance

terraform {
  required_version = ">= 1.10"  # Required for S3 native locking
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  # Optional: Use specific AWS profile for production environment
  # profile = "backend-booking-prod"
  
  # Optional: Assume role for cross-account access
  # assume_role {
  #   role_arn     = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
  #   session_name = "terraform-prod"
  # }
  
  # Default tags applied to all resources
  default_tags {
    tags = {
      Environment = "prod"
      Project     = "backend-booking"
      ManagedBy   = "Terraform"
      Repository  = "backend_booking_infra"
      CostCenter  = "Production"
      Critical    = "true"
    }
  }
  
  # Enhanced retry configuration for production stability
  retry_mode  = "adaptive"
  max_retries = 5
  
  # Optional: Custom endpoints for private AWS deployments
  # endpoints {
  #   s3  = "https://s3.us-east-1.amazonaws.com"
  #   ecs = "https://ecs.us-east-1.amazonaws.com"
  #   rds = "https://rds.us-east-1.amazonaws.com"
  # }
}