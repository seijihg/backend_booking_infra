variable "aws_region" {
  description = "AWS region where the backend resources will be created"
  type        = string
  default     = "eu-west-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage with native locking"
  type        = string
  # Default uses account ID to ensure uniqueness
  # Override this with your specific bucket name
  default     = ""
}

variable "kms_key_id" {
  description = "KMS key ID for S3 bucket encryption (optional)"
  type        = string
  default     = ""
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which to expire noncurrent object versions"
  type        = number
  default     = 90
}

variable "noncurrent_version_transition_days" {
  description = "Days after which to transition noncurrent versions to STANDARD_IA"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "s3_request_threshold" {
  description = "Threshold for S3 request count alarm"
  type        = number
  default     = 1000
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}