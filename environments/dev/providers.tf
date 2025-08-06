# Provider Configuration for Development Environment
# Uses AWS Provider 6.0 with enhanced features and performance

terraform {
  required_version = ">= 1.10"  # Required for S3 native locking
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  
  # Backend configuration using S3 with native locking
  backend "s3" {
    bucket       = "backend-booking-terraform-state-826601724385"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true  # Enable S3 native state locking (Terraform >= 1.10)
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  # Optional: Use specific AWS profile for dev environment
  # profile = "backend-booking-dev"
  
  # Optional: Assume role for cross-account access
  # assume_role {
  #   role_arn     = "arn:aws:iam::ACCOUNT_ID:role/TerraformRole"
  #   session_name = "terraform-dev"
  # }
  
  # Default tags applied to all resources
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "backend-booking"
      ManagedBy   = "Terraform"
      Repository  = "backend_booking_infra"
      CostCenter  = "Development"
    }
  }
  
  # Optional: Retry configuration for API rate limiting
  retry_mode  = "adaptive"
  max_retries = 3
}