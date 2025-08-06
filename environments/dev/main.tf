# Development Environment Main Configuration
# Backend configuration for Terraform state management

terraform {
  required_version = ">= 1.10"
  
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

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.app_name
      ManagedBy   = "Terraform"
      CostCenter  = "Development"
    }
  }
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}