# Development Environment Main Configuration

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}