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

```bash
# Deploy development environment
cd environments/dev
terraform init
terraform plan
terraform apply

# CodePipeline will automatically deploy application updates when code is pushed to the dev branch
```
