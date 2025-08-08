# ECS Module Deployment Guide

## ✅ ECS Module Successfully Imported

The ECS module has been integrated into the dev environment with the following components:

### Resources to be Created (29 total)

**Container Infrastructure:**
- ECR Repository for Docker images with lifecycle policy
- ECS Cluster with Fargate support
- ECS Service with auto-scaling
- Task definition for the application

**Security & IAM:**
- IAM roles for task execution and application
- Security group for ECS tasks
- Secrets Manager for sensitive configuration

**Monitoring & Scaling:**
- CloudWatch log groups
- Auto-scaling policies (CPU and memory based)
- CloudWatch alarms for monitoring

**Load Balancing:**
- Target group for ALB integration

## Deployment Steps

### 1. Deploy the Infrastructure
```bash
terraform apply -lock=false
```

### 2. Build and Push Docker Image
```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url | cut -d'/' -f1)

# Build your Django application
docker build -t backend-booking:latest .

# Tag for ECR
docker tag backend-booking:latest $(terraform output -raw ecr_repository_url):latest

# Push to ECR
docker push $(terraform output -raw ecr_repository_url):latest
```

### 3. Update ECS Service (if needed)
```bash
# Force new deployment after pushing new image
aws ecs update-service \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service $(terraform output -raw ecs_service_name) \
  --force-new-deployment \
  --region eu-west-2
```

## Configuration Details

**Current Settings (dev):**
- CPU: 256 (0.25 vCPU)
- Memory: 512 MB
- Tasks: 1 (min) - 2 (max)
- Fargate Spot: Enabled (cost savings)
- ECS Exec: Enabled (for debugging)

## Cost Optimization

**Dev Environment Optimizations:**
- Fargate Spot enabled (up to 70% savings)
- Minimal resources (256 CPU, 512 MB RAM)
- Single task with max 2 for auto-scaling
- 7-day log retention

**Estimated Monthly Cost:**
- Fargate: ~$10-15 (with Spot)
- ECR: ~$1 (10 images)
- Secrets Manager: ~$2
- CloudWatch Logs: ~$1
- **Total: ~$15-20/month**

## Next Steps

1. **Deploy ALB Module** - For load balancing and SSL termination
2. **Deploy RDS Module** - PostgreSQL database
3. **Deploy Redis Module** - ElastiCache for caching
4. **Deploy S3 Module** - Static file storage
5. **Configure Domain & SSL** - Route53 and ACM

## Troubleshooting

### ECS Task Not Starting
- Check CloudWatch logs: `/ecs/backend-booking-dev`
- Verify ECR image exists
- Check security group rules
- Verify secrets in Secrets Manager

### Cannot Connect to Application
- ALB module needs to be deployed
- Check target group health checks
- Verify security group allows traffic

### Debugging with ECS Exec
```bash
aws ecs execute-command \
  --cluster backend-booking-dev-cluster \
  --task <task-id> \
  --container backend-booking \
  --interactive \
  --command "/bin/bash"
```

## Module Dependencies

The ECS module currently has placeholders for:
- S3 bucket (for static files)
- RDS database connection
- Redis connection
- CloudFront distribution

These will be automatically configured when their respective modules are deployed.