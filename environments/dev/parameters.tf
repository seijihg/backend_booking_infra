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
