# CodeBuild Project for building Docker images and pushing to ECR

# CodeBuild Project
resource "aws_codebuild_project" "main" {
  name          = "${var.app_name}-${var.environment}-build"
  description   = "Build Docker image and push to ECR for ${var.app_name}"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.build_compute_type
    image                      = var.build_image
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true  # Required for Docker

    # Environment variables for the build
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.ecr_repository_url
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }

    environment_variable {
      name  = "APP_NAME"
      value = var.app_name
    }

    # Parameter Store paths for build-time secrets (if needed)
    dynamic "environment_variable" {
      for_each = var.build_parameter_store_secrets
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PARAMETER_STORE"
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yml")
  }

  # VPC Configuration (optional - for accessing private resources during build)
  dynamic "vpc_config" {
    for_each = var.enable_vpc_config ? [1] : []
    content {
      vpc_id             = var.vpc_id
      subnets            = var.private_subnet_ids
      security_group_ids = [aws_security_group.codebuild[0].id]
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = "build-log"
    }

    # Optional S3 logs
    dynamic "s3_logs" {
      for_each = var.enable_s3_logs ? [1] : []
      content {
        status   = "ENABLED"
        location = "${aws_s3_bucket.pipeline_artifacts.id}/build-logs"
      }
    }
  }

  # Build timeout
  build_timeout = var.build_timeout
  queued_timeout = var.queued_timeout

  # Build badge
  badge_enabled = var.enable_build_badge

  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-build"
      Environment = var.environment
    }
  )
}

# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.app_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-codebuild-logs"
      Environment = var.environment
    }
  )
}

# Security Group for CodeBuild (if VPC is enabled)
resource "aws_security_group" "codebuild" {
  count = var.enable_vpc_config ? 1 : 0

  name        = "${var.app_name}-${var.environment}-codebuild-sg"
  description = "Security group for CodeBuild project"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-codebuild-sg"
      Environment = var.environment
    }
  )
}