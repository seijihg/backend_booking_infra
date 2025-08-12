# CodePipeline Module - CI/CD Pipeline for ECS Deployment

# CodeStar Connection for GitHub (v2 - recommended approach)
resource "aws_codestarconnections_connection" "github" {
  # Name must be ≤32 characters
  name          = "${var.app_name}-${var.environment}-github"
  provider_type = "GitHub"

  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-github-connection"
      Environment = var.environment
      Purpose     = "GitHub integration for CodePipeline"
    }
  )
}

# S3 Bucket for Pipeline Artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.app_name}-${var.environment}-pipeline-artifacts-${data.aws_caller_identity.current.account_id}"
  
  # Allow Terraform to delete the bucket even if it contains objects
  force_destroy = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-pipeline-artifacts"
      Environment = var.environment
      Purpose     = "CodePipeline artifacts"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data source for current AWS identity
data "aws_caller_identity" "current" {}

# Data source for current region
data "aws_region" "current" {}

# CodePipeline
resource "aws_codepipeline" "main" {
  name     = "${var.app_name}-${var.environment}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  # Source Stage - GitHub v2 with CodeStar Connection
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName       = var.github_branch
        
        # Optional: Enable git clone depth for faster checkouts
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  # Build Stage - CodeBuild
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  # Deploy Stage - ECS
  stage {
    name = "Deploy"

    # Manual Approval (optional for production)
    dynamic "action" {
      for_each = var.require_manual_approval ? [1] : []
      content {
        name     = "ManualApproval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = {
          CustomData = "Please review and approve deployment to ${var.environment}"
        }
      }
    }

    # Deploy to ECS
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName       = var.ecs_cluster_name
        ServiceName       = var.ecs_service_name
        FileName          = "imagedefinitions.json"
        DeploymentTimeout = var.deployment_timeout
      }
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.app_name}-${var.environment}-pipeline"
      Environment = var.environment
    }
  )
}