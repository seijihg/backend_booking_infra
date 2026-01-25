# backend_booking_infra

Infrastructure as Code (IaC) for deploying the Backend Booking Django application to AWS using Terraform.

## Current Status

### Development Environment

- ✅ **VPC and Networking**: Fully configured with public/private subnets
- ✅ **RDS PostgreSQL**: Running and accessible
- ✅ **ElastiCache Redis**: Deployed and operational
- ✅ **ECS Cluster**: Active with Fargate tasks
- ✅ **Application Load Balancer**: Configured and routing traffic
- ✅ **S3 Buckets**: Static and media storage configured
- ✅ **Parameter Store**: All secrets and configurations loaded
- ✅ **CodePipeline CI/CD**: Successfully deployed and operational
  - Automated deployments from `dev` branch
  - Docker image builds and ECR push working
  - ECS service updates triggered automatically

### Production Environment

- 🔄 Not yet deployed (pending domain and SSL setup)

## Quick Start

### Using Makefile (Recommended)

The Makefile uses `aws-vault` with the `--no-session` flag to avoid IAM/STS regional endpoint compatibility issues.

```bash
# Initialize and plan
make init
make plan

# Apply changes
make apply

# Environment-specific commands
make dev-plan      # Plan for dev
make prod-apply    # Apply to prod

# Use different AWS profile
make plan AWS_PROFILE=other

# See all available commands
make help
```

### Manual Commands

```bash
# Deploy development environment
cd environments/dev
aws-vault exec le --no-session -- terraform init
aws-vault exec le --no-session -- terraform plan
aws-vault exec le --no-session -- terraform apply
```

> **Note**: The `--no-session` flag is required because aws-vault's session tokens from regional STS endpoints don't work with the global IAM service.

### CI/CD

CodePipeline will automatically deploy application updates when code is pushed to the dev branch.
