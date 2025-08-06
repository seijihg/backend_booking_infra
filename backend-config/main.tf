# Terraform Backend Configuration Setup
# This configuration creates the S3 bucket for Terraform state management with native S3 locking
# Run this ONCE before setting up any environments

terraform {
  required_version = ">= 1.10" # Required for S3 native locking
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = "backend-booking"
      ManagedBy  = "Terraform"
      Repository = "backend_booking_infra"
    }
  }
}

# Use the terraform-backend module to create state storage infrastructure
module "terraform_backend" {
  source = "../modules/terraform-backend"

  bucket_name = var.state_bucket_name
  environment = "shared"

  # Security configurations
  kms_key_id = var.kms_key_id

  # Lifecycle configurations
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  noncurrent_version_transition_days = var.noncurrent_version_transition_days

  # Monitoring
  enable_monitoring    = var.enable_monitoring
  s3_request_threshold = var.s3_request_threshold
  alarm_actions        = var.alarm_actions

  tags = {
    Purpose     = "Terraform State Management"
    Environment = "shared"
    Critical    = "true"
  }
}
