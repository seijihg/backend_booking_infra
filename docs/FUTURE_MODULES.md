# Future Modules Integration Plan

This document outlines the modules that will be created to complete the ECS infrastructure once the Docker images are ready in ECR.

## Current State

✅ **Completed:**
- ECS Cluster (infrastructure only)
- ECR Repository
- IAM Roles (task execution and task roles)
- CloudWatch Log Groups
- VPC and Networking
- Security Groups
- Parameter Store configuration
- Application Load Balancer (ALB) with target group
- CodePipeline CI/CD module (ready for GitHub integration)

## Future Modules

### 1. ECS Task Definition Module (`modules/ecs-task-definition`)

**When to implement:** After Docker image is built and pushed to ECR

**Purpose:** Define how containers should run

```hcl
module "app_task_definition" {
  source = "../../modules/ecs-task-definition"
  
  family      = "${var.app_name}-${var.environment}"
  task_role_arn       = module.ecs_cluster.task_role_arn
  execution_role_arn  = module.ecs_cluster.task_execution_role_arn
  
  # Container Definition
  container_name   = var.app_name
  image           = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
  cpu             = 512
  memory          = 1024
  container_port  = 8000
  
  # Environment Variables
  environment_variables = {
    DJANGO_SETTINGS_MODULE = "config.settings.production"
    ALLOWED_HOSTS         = var.allowed_hosts
  }
  
  # Secrets from Parameter Store
  secrets = {
    DJANGO_SECRET_KEY = "/backend-booking/${var.environment}/app/django-secret-key"
    DATABASE_PASSWORD = "/backend-booking/${var.environment}/database/password"
  }
  
  # CloudWatch Logs
  log_group = module.ecs_cluster.log_group_name
}
```

### 2. ECS Service Module (`modules/ecs-service`)

**When to implement:** After ALB is fully configured

**Purpose:** Manage running tasks and integrate with load balancer

```hcl
module "app_service" {
  source = "../../modules/ecs-service"
  
  name            = "${var.app_name}-${var.environment}"
  cluster_id      = module.ecs_cluster.cluster_id
  task_definition = module.app_task_definition.arn
  
  # Networking
  subnets         = [module.networking.private_subnet_id]
  security_groups = [aws_security_group.ecs_tasks.id]
  
  # Load Balancer
  target_group_arn = aws_lb_target_group.app.arn
  container_name   = var.app_name
  container_port   = 8000
  
  # Scaling
  desired_count = 2
  min_capacity  = 1
  max_capacity  = 5
  
  # Auto-scaling policies
  cpu_target_value    = 70
  memory_target_value = 80
}
```

### 3. ~~ALB Module~~ ✅ **COMPLETED**

The Application Load Balancer module has been implemented and integrated into the dev environment.

**What's configured:**
- Internet-facing ALB in public subnet
- Target group with health checks (path: `/health/`)
- HTTP listener on port 80
- CloudWatch alarms for monitoring
- Ready for SSL/TLS when certificate is available

**Access the ALB:**
After deployment, the ALB will be accessible at the DNS name output by Terraform.

### 4. Worker Task Module (`modules/ecs-worker`)

**When to implement:** After main application is running

**Purpose:** Background job processing with Dramatiq

```hcl
module "worker_tasks" {
  source = "../../modules/ecs-worker"
  
  cluster_id = module.ecs_cluster.cluster_id
  
  # Task Definition
  family             = "${var.app_name}-${var.environment}-worker"
  image             = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
  command           = ["python", "manage.py", "rundramatiq"]
  
  # Resources
  cpu    = 256
  memory = 512
  
  # Scaling
  desired_count = 1
  min_capacity  = 1
  max_capacity  = 3
  
  # Queue-based scaling
  scale_on_queue_depth = true
  queue_depth_target   = 100
}
```

## Integration Timeline

### Phase 1: Basic Infrastructure (Current)
- ✅ ECS Cluster
- ✅ ECR Repository
- ✅ Networking
- ✅ Security Groups

### Phase 2: Load Balancer
- [ ] ALB Module
- [ ] DNS Configuration
- [ ] SSL Certificate (optional)

### Phase 3: Application Deployment
- [ ] Build and push Docker image to ECR
- [ ] Create Task Definition module
- [ ] Create Service module
- [ ] Configure health checks

### Phase 4: Production Readiness
- [ ] Auto-scaling policies
- [ ] CloudWatch alarms
- [ ] Backup strategies
- [ ] Blue-green deployment

### Phase 5: Advanced Features
- [ ] Worker tasks (Dramatiq)
- [ ] Service discovery
- [ ] API Gateway (if needed)
- [ ] CloudFront CDN

## Migration Commands

When ready to deploy tasks and services:

```bash
# 1. Build and push Docker image
docker build -t backend-booking .
docker tag backend-booking:latest $ECR_URL:latest
docker push $ECR_URL:latest

# 2. Apply infrastructure with new modules
cd environments/dev
terraform plan
terraform apply

# 3. Verify deployment
aws ecs describe-services --cluster backend-booking-dev-cluster --services backend-booking-dev
```

## Important Notes

1. **Order of Implementation:**
   - ALB can be created anytime
   - Task definitions require Docker images in ECR
   - Services require both task definitions and target groups

2. **Cost Considerations:**
   - ALB costs ~$20/month regardless of traffic
   - Each running task incurs Fargate costs
   - Consider Fargate Spot for development

3. **Security:**
   - All sensitive data via Parameter Store
   - Tasks run in private subnets
   - ALB handles SSL termination

4. **Monitoring:**
   - CloudWatch Container Insights enabled
   - Custom metrics for application monitoring
   - Alarms for critical thresholds