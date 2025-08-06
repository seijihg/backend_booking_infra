# Terraform Backend Infrastructure Module
# This module creates an S3 bucket for Terraform state storage with native S3 locking
# Uses S3 Conditional Writes for state locking (no DynamoDB required)

terraform {
  required_version = ">= 1.10" # Required for S3 native locking
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name        = var.bucket_name
      Purpose     = "Terraform State Storage with Native Locking"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning for state file history and rollback capability
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for security
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
    }
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket lifecycle policy for managing old state versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    # Filter applies to all objects in the bucket
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    noncurrent_version_transition {
      noncurrent_days = var.noncurrent_version_transition_days
      storage_class   = "STANDARD_IA"
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    # Filter applies to all objects in the bucket
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# IAM policy for accessing the state bucket
resource "aws_iam_policy" "terraform_backend_policy" {
  name        = "${var.bucket_name}-backend-policy"
  path        = "/"
  description = "IAM policy for accessing Terraform state backend with native S3 locking"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListStateBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "GetPutDeleteStateFiles"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      }
    ]
  })
}

# CloudWatch alarm for monitoring state file access (optional)
resource "aws_cloudwatch_metric_alarm" "high_s3_requests" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.bucket_name}-high-request-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Average"
  threshold           = var.s3_request_threshold
  alarm_description   = "This metric monitors S3 bucket request count for Terraform state operations"

  dimensions = {
    BucketName  = aws_s3_bucket.terraform_state.id
    StorageType = "AllStorageTypes"
  }

  alarm_actions = var.alarm_actions
}

# CloudWatch alarm for monitoring failed state operations (optional)
resource "aws_cloudwatch_metric_alarm" "s3_4xx_errors" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.bucket_name}-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert on S3 4xx errors which may indicate permission issues"

  dimensions = {
    BucketName = aws_s3_bucket.terraform_state.id
  }

  alarm_actions = var.alarm_actions
}
