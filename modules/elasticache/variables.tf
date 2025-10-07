# ElastiCache Redis Module Variables - Simplified

# Required Variables
variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Redis will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for Redis (use multiple AZs for production)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs that can access Redis (typically ECS tasks)"
  type        = list(string)
}

# Optional Variables with Sensible Defaults
variable "node_type" {
  description = "Redis instance type (t3.micro for dev, t3.small+ for prod)"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes (1 for dev, 2+ for prod with multi-az)"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "multi_az_enabled" {
  description = "Enable Multi-AZ for high availability (recommended for production)"
  type        = bool
  default     = false
}

variable "snapshot_retention_limit" {
  description = "Number of days to retain snapshots (0 to disable, 5-7 for production)"
  type        = number
  default     = 0
}

variable "enable_auth_token" {
  description = "Enable AUTH token for Redis (requires TLS, recommended for production)"
  type        = bool
  default     = false
}

variable "auth_token" {
  description = "AUTH token for Redis (only used if enable_auth_token is true)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
