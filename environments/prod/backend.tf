# Terraform Backend Configuration for Production Environment
# This file configures remote state storage in S3 with native S3 locking

terraform {
  required_version = ">= 1.10"  # Required for S3 native locking
  
  backend "s3" {
    # These values should be updated after running the backend-config setup
    # Replace with actual values from backend-config output
    
    bucket       = "backend-booking-terraform-state-826601724385"
    key          = "prod/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true  # Enable S3 native state locking (no DynamoDB needed)
    
    # Optional: Use a specific profile
    # profile = "backend-booking-prod"
    
    # Optional: Use specific IAM role for state management
    # role_arn = "arn:aws:iam::ACCOUNT_ID:role/terraform-backend-role"
    
    # Additional security for production
    # Enable workspaces if needed
    # workspace_key_prefix = "workspaces"
  }
}