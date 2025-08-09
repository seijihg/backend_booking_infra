# VPC Endpoints Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-2"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for endpoints"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of private route table IDs for S3 endpoint"
  type        = list(string)
}

# Security Group Configuration
variable "security_group_ids" {
  description = "Security group IDs that need access to VPC endpoints"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

# Enable/Disable Endpoints
variable "enable_ssm_endpoints" {
  description = "Enable Systems Manager endpoints for Parameter Store"
  type        = bool
  default     = true
}

variable "enable_ecr_endpoints" {
  description = "Enable ECR endpoints for Docker registry"
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable S3 endpoint (gateway type)"
  type        = bool
  default     = true
}

variable "enable_logs_endpoint" {
  description = "Enable CloudWatch Logs endpoint"
  type        = bool
  default     = true
}

variable "enable_secrets_manager_endpoint" {
  description = "Enable Secrets Manager endpoint (if using Secrets Manager)"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}