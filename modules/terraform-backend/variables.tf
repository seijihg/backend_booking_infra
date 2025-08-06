variable "bucket_name" {
  description = "The name of the S3 bucket for Terraform state storage"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase alphanumeric with hyphens, and cannot start or end with a hyphen."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, shared)"
  type        = string
  validation {
    condition     = contains(["dev", "prod", "shared"], var.environment)
    error_message = "Environment must be one of: dev, prod, shared."
  }
}

variable "kms_key_id" {
  description = "The AWS KMS key ID to use for S3 bucket encryption (optional, uses AWS managed key if not specified)"
  type        = string
  default     = ""
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which to expire noncurrent object versions"
  type        = number
  default     = 90
}

variable "noncurrent_version_transition_days" {
  description = "Number of days after which to transition noncurrent versions to STANDARD_IA storage class"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms for S3 bucket operations"
  type        = bool
  default     = false
}

variable "s3_request_threshold" {
  description = "Threshold for S3 request count alarm (requests per 5 minutes)"
  type        = number
  default     = 1000
}

variable "alarm_actions" {
  description = "List of SNS topic ARNs to notify when CloudWatch alarms trigger"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}