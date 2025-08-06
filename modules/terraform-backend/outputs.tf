output "s3_bucket_id" {
  description = "The ID of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_region" {
  description = "The AWS region where the S3 bucket is located"
  value       = aws_s3_bucket.terraform_state.region
}

output "backend_iam_policy_arn" {
  description = "The ARN of the IAM policy for backend access"
  value       = aws_iam_policy.terraform_backend_policy.arn
}

output "backend_config" {
  description = "Backend configuration for use in terraform backend block with S3 native locking"
  value = {
    bucket       = aws_s3_bucket.terraform_state.id
    key          = "terraform.tfstate"  # Update with environment-specific path
    region       = aws_s3_bucket.terraform_state.region
    encrypt      = true
    use_lockfile = true  # Enable S3 native locking
  }
}

output "backend_config_example" {
  description = "Example backend configuration block for Terraform files with S3 native locking"
  value = <<-EOT
    terraform {
      required_version = ">= 1.10"  # Required for S3 native locking
      
      backend "s3" {
        bucket       = "${aws_s3_bucket.terraform_state.id}"
        key          = "environment/terraform.tfstate"  # Change 'environment' to dev/staging/prod
        region       = "${aws_s3_bucket.terraform_state.region}"
        encrypt      = true
        use_lockfile = true  # Enable S3 native state locking (no DynamoDB needed)
      }
    }
  EOT
}