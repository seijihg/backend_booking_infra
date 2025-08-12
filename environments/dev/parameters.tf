# AWS Systems Manager Parameter Store Configuration for Development Environment

# Application Parameters
resource "aws_ssm_parameter" "django_secret_key" {
  name  = "/backend-booking/${var.environment}/app/django-secret-key"
  type  = "SecureString"
  value = var.django_secret_key != "" ? var.django_secret_key : "dev-secret-key-change-in-production"

  tags = {
    Name        = "Django Secret Key"
    Environment = var.environment
    Service     = "app"
  }
}

resource "aws_ssm_parameter" "allowed_hosts" {
  name  = "/backend-booking/${var.environment}/app/allowed-hosts"
  type  = "String"
  value = var.allowed_hosts

  tags = {
    Name        = "Allowed Hosts"
    Environment = var.environment
    Service     = "app"
  }
}

# Debug mode is not used by the application, removed parameter
# If needed in future, can be set directly as environment variable

# Local variables to ensure consistency between all parameters
locals {
  # Database values - defined once to ensure consistency
  db_username = "backend_booking_${var.environment}"
  db_password = var.database_password != "" ? var.database_password : "dev-password-change-in-production"
  db_host     = var.database_host != "" ? var.database_host : "placeholder-will-be-updated-when-rds-deployed"
  db_name     = var.database_name
  db_port     = "5432"
  
  # Redis values - defined once to ensure consistency
  redis_host = var.redis_host != "" ? var.redis_host : "placeholder-will-be-updated-when-redis-deployed"
  redis_port = "6379"
  redis_db   = "0"
  
  # Construct URLs from the same values
  database_url = "postgresql://${local.db_username}:${local.db_password}@${local.db_host}:${local.db_port}/${local.db_name}"
  redis_url    = "redis://${local.redis_host}:${local.redis_port}/${local.redis_db}"
}

# Database Parameters
# Using a single DATABASE_URL for Django application
resource "aws_ssm_parameter" "database_url" {
  name      = "/backend-booking/${var.environment}/database/url"
  type      = "SecureString"  # SecureString since it contains password
  value     = local.database_url
  overwrite = true  # Allow overwriting existing parameter

  tags = {
    Name        = "Database URL"
    Environment = var.environment
    Service     = "database"
  }

  lifecycle {
    ignore_changes = [value]  # Don't overwrite the value if it's been manually changed
  }
}

# Individual parameters for PgBouncer sidecar container
# IMPORTANT: ALL database parameters are managed by the RDS module.
# The RDS module creates these parameters:
# - /backend-booking/{env}/database/host
# - /backend-booking/{env}/database/name  
# - /backend-booking/{env}/database/username
# - /backend-booking/{env}/database/password
# - /backend-booking/{env}/database/port
#
# The RDS module is configured with update_parameter_store = true.
# If ECS tasks fail with "invalid ssm parameters" errors, ensure:
# 1. The RDS module has been applied (terraform apply)
# 2. The parameters exist in AWS SSM Parameter Store
# 3. The ECS task execution role has ssm:GetParameter permissions

# Redis Parameters
# Redis URL for the application (using locals defined above)
resource "aws_ssm_parameter" "redis_url" {
  name      = "/backend-booking/${var.environment}/redis/url"
  type      = "String"
  value     = local.redis_url
  overwrite = true  # Allow overwriting existing parameter

  tags = {
    Name        = "Redis URL"
    Environment = var.environment
    Service     = "redis"
  }

  lifecycle {
    ignore_changes = [value]  # Don't overwrite the value if it's been manually changed
  }
}

# AWS Configuration Parameters
# AWS region is provided directly to task definition, no need for parameter
# Removed unused aws_region parameter

resource "aws_ssm_parameter" "s3_bucket_name" {
  name  = "/backend-booking/${var.environment}/aws/s3-bucket-name"
  type  = "String"
  value = var.s3_bucket_name != "" ? var.s3_bucket_name : "${var.app_name}-${var.environment}-static"

  tags = {
    Name        = "S3 Bucket Name"
    Environment = var.environment
    Service     = "aws"
  }
}

resource "aws_ssm_parameter" "cloudfront_distribution_id" {
  count = var.cloudfront_distribution_id != "" ? 1 : 0  # Only create if value is provided
  
  name  = "/backend-booking/${var.environment}/aws/cloudfront-distribution-id"
  type  = "String"
  value = var.cloudfront_distribution_id

  tags = {
    Name        = "CloudFront Distribution ID"
    Environment = var.environment
    Service     = "aws"
  }
}

# Third-party Service Parameters
resource "aws_ssm_parameter" "twilio_account_sid" {
  count = var.twilio_account_sid != "" ? 1 : 0  # Only create if value is provided
  
  name  = "/backend-booking/${var.environment}/third-party/twilio-account-sid"
  type  = "String"
  value = var.twilio_account_sid

  tags = {
    Name        = "Twilio Account SID"
    Environment = var.environment
    Service     = "third-party"
  }
}

resource "aws_ssm_parameter" "twilio_auth_token" {
  count = var.twilio_auth_token != "" ? 1 : 0  # Only create if value is provided
  
  name  = "/backend-booking/${var.environment}/third-party/twilio-auth-token"
  type  = "SecureString"
  value = var.twilio_auth_token

  tags = {
    Name        = "Twilio Auth Token"
    Environment = var.environment
    Service     = "third-party"
  }
}

resource "aws_ssm_parameter" "twilio_phone_number" {
  name  = "/backend-booking/${var.environment}/third-party/twilio-phone-number"
  type  = "String"
  value = var.twilio_phone_number

  tags = {
    Name        = "Twilio Phone Number"
    Environment = var.environment
    Service     = "third-party"
  }
}

# Seed Data Parameters
resource "aws_ssm_parameter" "seed_owner_default_password" {
  name  = "/backend-booking/${var.environment}/seed-data/owner-default-password"
  type  = "SecureString"
  value = var.seed_owner_password != "" ? var.seed_owner_password : "changeme123"  # Use default if empty

  tags = {
    Name        = "Seed Owner Default Password"
    Environment = var.environment
    Service     = "seed-data"
  }
}

# CI/CD Parameters
# Note: GitHub integration now uses AWS CodeStar Connections (v2) instead of OAuth tokens
# The connection must be manually approved in the AWS Console after creation
# No GitHub token is required in Parameter Store anymore
# The github_token_placeholder resource below has been disabled (count = 0)

resource "aws_ssm_parameter" "github_token_placeholder" {
  count = 0  # DEPRECATED - CodeStar Connections v2 doesn't need GitHub tokens
  
  name  = "/backend-booking/common/github-token"
  type  = "SecureString"
  value = "DEPRECATED - No longer needed with CodeStar Connections"

  tags = {
    Name        = "DEPRECATED - GitHub Token (not needed with CodeStar)"
    Environment = "common"
    Service     = "ci-cd"
    Note        = "CodeStar Connections v2 replaces OAuth tokens"
  }
  
  lifecycle {
    ignore_changes = [value]
  }
}
