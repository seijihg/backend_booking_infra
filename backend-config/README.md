# Terraform Backend Configuration

This directory contains the configuration for setting up the Terraform backend infrastructure using S3 with native state locking.

## 🚀 What's New: S3 Native Locking

Terraform now supports native S3 state locking using AWS S3's Conditional Writes feature, providing:

- **Cost Savings**: No DynamoDB table costs
- **Simpler Infrastructure**: Only S3 bucket needed
- **Atomic Operations**: Uses S3 Conditional Writes for safe concurrent access
- **Lock Files**: Stored alongside state files with `.tflock` extension

## Purpose

The backend configuration provides:

- **S3 Bucket**: Stores Terraform state files with versioning and encryption
- **Native State Locking**: Prevents concurrent modifications using S3's built-in features
- **IAM Policy**: Defines permissions for accessing the backend resources

## Prerequisites

1. **Terraform >= 1.10** (required for S3 native locking)
2. AWS CLI configured with appropriate credentials
3. Appropriate AWS permissions to create S3 buckets and IAM policies

## Setup Instructions

### Quick Setup (Recommended)

Use the provided initialization script:

```bash
# From the project root
./scripts/init-backend.sh

# Or with a custom bucket name
./scripts/init-backend.sh "my-custom-terraform-state-bucket"
```

The script will:

- Check Terraform version (must be >= 1.10)
- Create the S3 bucket with proper configuration
- Set up encryption and versioning
- Configure all environments to use S3 native locking

### Manual Setup

1. Navigate to this directory:

   ```bash
   cd backend-config
   ```

2. Copy the example configuration:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your values:

   ```hcl
   aws_region = "us-east-1"
   state_bucket_name = "backend-booking-terraform-state-<your-account-id>"
   enable_monitoring = true
   ```

4. Initialize and apply:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. Note the outputs - you'll need these for configuring your environments.

## Using the Backend

After creating the backend infrastructure, configure your Terraform environments to use it:

```hcl
terraform {
  required_version = ">= 1.10"  # Required for S3 native locking

  backend "s3" {
    bucket       = "backend-booking-terraform-state-123456789012"
    key          = "dev/terraform.tfstate"  # Use dev/prod
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true  # Enable S3 native state locking
  }
}
```

## Features

### Security

- **Encryption**: Server-side encryption with KMS (optional custom key) or AES256
- **Versioning**: All state file versions are retained for rollback capability
- **Access Control**: Public access is completely blocked
- **IAM Policy**: Least-privilege access policy included

### State Locking

- **Native S3 Locking**: Uses S3 Conditional Writes (no DynamoDB needed)
- **Lock Files**: Created with `.tflock` extension in the same location as state files
- **Atomic Operations**: Ensures only one Terraform operation can modify state at a time
- **Automatic Release**: Locks are automatically released when operations complete

### Lifecycle Management

- **Version Transitions**: Old versions moved to STANDARD_IA after 30 days
- **Version Expiration**: Old versions deleted after 90 days (configurable)
- **Incomplete Uploads**: Automatically cleaned up after 7 days

### High Availability

- **Multi-AZ Storage**: S3 automatically replicates across multiple AZs
- **99.999999999% Durability**: S3's eleven 9s durability guarantee
- **Cross-Region Replication**: Can be enabled for disaster recovery (optional)

### Monitoring

- **CloudWatch Alarms**: Monitor high request counts (optional)
- **4xx Error Alerts**: Detect permission or configuration issues
- **Metrics**: Track S3 usage and access patterns

## Important Notes

1. **Terraform Version**: Requires Terraform >= 1.10 for S3 native locking support

2. **One-Time Setup**: This backend configuration should be created once and shared across all environments

3. **State Bootstrap**: The backend configuration itself uses local state. Do not delete the local state file in this directory

4. **Bucket Naming**: S3 bucket names must be globally unique. The default uses your AWS account ID to ensure uniqueness

5. **Prevent Destroy**: The S3 bucket has `prevent_destroy` lifecycle rules to prevent accidental deletion

## Maintenance

### View Backend Information

```bash
./scripts/init-backend.sh info
```

### Initialize Environment Backends

```bash
./scripts/init-backend.sh init-envs
```

### Update Environment Configurations

```bash
./scripts/init-backend.sh update-envs
```

### Destroy Backend (Use with Caution!)

```bash
./scripts/init-backend.sh destroy
```

## Troubleshooting

### "Terraform Version Too Old" Error

Upgrade to Terraform 1.10 or newer:

```bash
# Using tfenv
tfenv install 1.10.0
tfenv use 1.10.0

# Or download directly from HashiCorp
```

### "Access Denied" Errors

Ensure your AWS credentials have permissions to:

- Create and manage S3 buckets
- Create IAM policies
- Put/Get/Delete S3 objects

### "Bucket Already Exists" Error

S3 bucket names are globally unique. Choose a different name in `terraform.tfvars`.

### State Lock Issues

With S3 native locking, lock files are automatically managed. If you encounter lock issues:

1. Wait for the current operation to complete
2. Check for `.tflock` files in the S3 bucket
3. Locks are automatically released when Terraform exits

### Viewing Lock Files

```bash
# List lock files in S3
aws s3 ls s3://your-bucket-name/ --recursive | grep .tflock
```

## Cost Estimates

Monthly costs (approximate):

- S3 Storage: $0.023 per GB
- S3 Requests: $0.0004 per 1,000 requests
- Total: Usually < $2/month for typical usage

**Cost Savings**: No DynamoDB costs (previously ~$1-5/month)

## Benefits of S3 Native Locking

1. **Simplified Architecture**: One less AWS service to manage
2. **Cost Reduction**: Eliminate DynamoDB costs
3. **Easier Permissions**: Only S3 permissions needed
4. **Better Integration**: Lock files stored with state files
5. **Atomic Operations**: Uses S3's built-in consistency guarantees

## Support

For issues or questions, please contact the infrastructure team or create an issue in the repository.
