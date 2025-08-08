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

resource "aws_ssm_parameter" "debug_mode" {
  name  = "/backend-booking/${var.environment}/app/debug-mode"
  type  = "String"
  value = var.environment == "dev" ? "true" : "false"

  tags = {
    Name        = "Debug Mode"
    Environment = var.environment
    Service     = "app"
  }
}

# Database Parameters
resource "aws_ssm_parameter" "database_host" {
  name  = "/backend-booking/${var.environment}/database/host"
  type  = "String"
  value = var.database_host != "" ? var.database_host : "placeholder-will-be-updated-when-rds-deployed"

  tags = {
    Name        = "Database Host"
    Environment = var.environment
    Service     = "database"
  }
}

resource "aws_ssm_parameter" "database_port" {
  name  = "/backend-booking/${var.environment}/database/port"
  type  = "String"
  value = "5432"

  tags = {
    Name        = "Database Port"
    Environment = var.environment
    Service     = "database"
  }
}

resource "aws_ssm_parameter" "database_name" {
  name  = "/backend-booking/${var.environment}/database/name"
  type  = "String"
  value = var.database_name

  tags = {
    Name        = "Database Name"
    Environment = var.environment
    Service     = "database"
  }
}

resource "aws_ssm_parameter" "database_username" {
  name  = "/backend-booking/${var.environment}/database/username"
  type  = "String"
  value = "backend_booking_${var.environment}"

  tags = {
    Name        = "Database Username"
    Environment = var.environment
    Service     = "database"
  }
}

resource "aws_ssm_parameter" "database_password" {
  name  = "/backend-booking/${var.environment}/database/password"
  type  = "SecureString"
  value = var.database_password != "" ? var.database_password : "dev-password-change-in-production"

  tags = {
    Name        = "Database Password"
    Environment = var.environment
    Service     = "database"
  }
}

# Redis Parameters
resource "aws_ssm_parameter" "redis_host" {
  name  = "/backend-booking/${var.environment}/redis/host"
  type  = "String"
  value = var.redis_host != "" ? var.redis_host : "placeholder-will-be-updated-when-redis-deployed"

  tags = {
    Name        = "Redis Host"
    Environment = var.environment
    Service     = "redis"
  }
}

resource "aws_ssm_parameter" "redis_port" {
  name  = "/backend-booking/${var.environment}/redis/port"
  type  = "String"
  value = "6379"

  tags = {
    Name        = "Redis Port"
    Environment = var.environment
    Service     = "redis"
  }
}

# AWS Configuration Parameters
resource "aws_ssm_parameter" "aws_region" {
  name  = "/backend-booking/${var.environment}/aws/region"
  type  = "String"
  value = var.aws_region

  tags = {
    Name        = "AWS Region"
    Environment = var.environment
    Service     = "aws"
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
