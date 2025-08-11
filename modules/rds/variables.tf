# RDS PostgreSQL Module Variables

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS (should be private subnets in different AZs)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security groups that can access the database"
  type        = list(string)
}

# Database Configuration
variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "backend_booking"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password for the database (will be stored in Parameter Store)"
  type        = string
  sensitive   = true
  default     = "" # If empty, will generate random password
}

variable "db_port" {
  description = "Port for the database"
  type        = number
  default     = 5432
}

# Instance Configuration
variable "instance_identifier" {
  description = "Identifier for the RDS instance"
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "Instance class for RDS"
  type        = string
  default     = "db.t3.micro" # Free tier eligible
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (0 to disable)"
  type        = number
  default     = 0 # Disabled for dev
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (uses default if not specified)"
  type        = string
  default     = ""
}

# Engine Configuration
variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.5" # Latest stable version
}

variable "family" {
  description = "DB parameter group family"
  type        = string
  default     = "postgres17"
}

# High Availability
variable "multi_az" {
  description = "Enable Multi-AZ for high availability"
  type        = bool
  default     = false # Disabled for dev to save costs
}

variable "availability_zone" {
  description = "Availability zone for single-AZ deployments"
  type        = string
  default     = ""
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = true # For dev environments
}

variable "final_snapshot_identifier" {
  description = "Name for final snapshot"
  type        = string
  default     = ""
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

# Monitoring
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval (0 to disable)"
  type        = number
  default     = 0 # Disabled for dev
}

variable "monitoring_role_arn" {
  description = "ARN for enhanced monitoring role"
  type        = string
  default     = ""
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false # Disabled for dev
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention in days"
  type        = number
  default     = 7
}

# Parameter Store Configuration
variable "parameter_store_path" {
  description = "Base path for Parameter Store parameters"
  type        = string
  default     = ""
}

variable "update_parameter_store" {
  description = "Update Parameter Store with database connection details"
  type        = bool
  default     = true
}

# Database Parameters
variable "db_parameters" {
  description = "Map of DB parameters to apply"
  type        = map(string)
  default = {
    shared_preload_libraries = "pg_stat_statements"
    log_statement            = "all"
    log_duration             = "1"  # Use "1" instead of "on" - AWS normalizes boolean values
  }
}

# Deletion Protection
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false # Disabled for dev
}

# Auto Minor Version Upgrade
variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

# Public Accessibility
variable "publicly_accessible" {
  description = "Make RDS instance publicly accessible"
  type        = bool
  default     = false # Should be in private subnet
}

# IAM Database Authentication
variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
