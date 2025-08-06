output "s3_bucket_id" {
  description = "The ID of the S3 bucket for Terraform state"
  value       = module.terraform_backend.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.terraform_backend.s3_bucket_arn
}

output "s3_bucket_region" {
  description = "The region of the S3 bucket"
  value       = module.terraform_backend.s3_bucket_region
}

output "backend_iam_policy_arn" {
  description = "The ARN of the IAM policy for backend access"
  value       = module.terraform_backend.backend_iam_policy_arn
}

output "backend_configuration" {
  description = "Backend configuration to use in your Terraform environments with S3 native locking"
  value = {
    bucket       = module.terraform_backend.s3_bucket_id
    key          = "<environment>/terraform.tfstate"  # Update <environment> with dev/prod
    region       = module.terraform_backend.s3_bucket_region
    encrypt      = true
    use_lockfile = true  # Enable S3 native locking
  }
}

output "backend_config_example" {
  description = "Example backend configuration block for your Terraform files with S3 native locking"
  value = <<-EOT
    terraform {
      required_version = ">= 1.10"  # Required for S3 native locking
      
      backend "s3" {
        bucket       = "${module.terraform_backend.s3_bucket_id}"
        key          = "dev/terraform.tfstate"  # Change 'dev' to your environment
        region       = "${module.terraform_backend.s3_bucket_region}"
        encrypt      = true
        use_lockfile = true  # Enable S3 native state locking (no DynamoDB needed)
      }
    }
  EOT
}