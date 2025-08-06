# Terraform Backend Configuration for Development Environment
# This file configures remote state storage in S3 with native S3 locking

terraform {
  required_version = ">= 1.10" # Required for S3 native locking

  backend "s3" {
    bucket       = "backend-booking-terraform-state-826601724385"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true # Enable S3 native state locking
  }
}
