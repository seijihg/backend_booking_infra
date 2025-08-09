# ECS Service Module

This module creates an ECS Service that manages running tasks on AWS Fargate with auto-scaling and load balancer integration.

## Features

- **Fargate Service Management** - Runs containerized tasks on serverless compute
- **Load Balancer Integration** - Connects to ALB target groups for traffic routing
- **Auto-scaling** - CPU, memory, and request-based scaling policies
- **Deployment Management** - Blue/green deployments with circuit breaker
- **Health Checks** - Grace period and health monitoring
- **CloudWatch Dashboard** - Service metrics visualization
- **ECS Exec** - SSH-like debugging capability (optional)

## Architecture

```
Application Load Balancer
         ↓
    Target Group
         ↓
    ECS Service
    ├── Task 1 (Container)
    ├── Task 2 (Container)
    └── Task N (Auto-scaled)
         ↓
    Auto-scaling
    ├── CPU Policy
    ├── Memory Policy
    └── Request Count Policy
```

## Usage

### Basic Example (Development)

```hcl
module "app_service" {
  source = "./modules/ecs-service"

  app_name    = "backend-booking"
  environment = "dev"
  
  # Cluster and Task
  cluster_id          = module.ecs_cluster.cluster_id
  task_definition_arn = module.task_definition.task_definition_arn
  
  # Network
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [aws_security_group.ecs_tasks.id]
  
  # Load Balancer
  enable_load_balancer = true
  target_group_arn    = module.alb.target_group_arn
  container_name      = "backend-booking"
  container_port      = 8000
  
  # Minimal for dev
  desired_count      = 1
  enable_autoscaling = false
  
  tags = {
    Environment = "dev"
  }
}
```

### Production Example with Auto-scaling

```hcl
module "app_service" {
  source = "./modules/ecs-service"

  app_name    = "backend-booking"
  environment = "prod"
  
  # Cluster and Task
  cluster_id          = module.ecs_cluster.cluster_id
  task_definition_arn = module.task_definition.task_definition_arn
  
  # Network (private subnets for security)
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [aws_security_group.ecs_tasks.id]
  assign_public_ip   = false
  
  # Load Balancer
  enable_load_balancer = true
  target_group_arn    = module.alb.target_group_arn
  container_name      = "backend-booking"
  container_port      = 8000
  
  # Production scaling
  desired_count      = 3
  enable_autoscaling = true
  min_capacity       = 2
  max_capacity       = 20
  
  # Scaling thresholds
  cpu_scale_up_threshold    = 60
  memory_scale_up_threshold = 70
  
  # Request-based scaling
  enable_request_count_scaling = true
  target_requests_per_task    = 500
  
  # Production deployment settings
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds = 120
  
  # Circuit breaker for safety
  enable_deployment_circuit_breaker = true
  enable_deployment_rollback       = true
  
  tags = {
    Environment = "prod"
    Critical    = "true"
  }
}
```

## Auto-scaling Configuration

### Scaling Policies

The module supports three types of auto-scaling:

1. **CPU-based Scaling**
   - Scales when average CPU utilization exceeds threshold
   - Default: Scale up at 70%, scale down at 30%

2. **Memory-based Scaling**
   - Scales when average memory utilization exceeds threshold
   - Default: Scale up at 70%, scale down at 30%

3. **Request Count Scaling** (Optional)
   - Scales based on ALB requests per task
   - Useful for web applications with variable traffic

### Scaling Best Practices

```hcl
# Conservative scaling for stability
scale_up_cooldown   = 60   # Quick scale up
scale_down_cooldown = 300  # Slow scale down

# Appropriate thresholds
cpu_scale_up_threshold = 60    # Not too aggressive
cpu_scale_down_threshold = 20  # Prevent flapping
```

## Deployment Configuration

### Circuit Breaker

Automatically rolls back failed deployments:

```hcl
enable_deployment_circuit_breaker = true
enable_deployment_rollback       = true
```

### Deployment Strategies

```hcl
# Rolling update (default)
deployment_maximum_percent = 200          # Can double tasks during deployment
deployment_minimum_healthy_percent = 100  # Keep all tasks running

# Blue/Green (future enhancement via CodeDeploy)
# Requires additional CodeDeploy configuration
```

## Health Checks

### Grace Period

Allow time for tasks to start:

```hcl
health_check_grace_period_seconds = 60  # Development
health_check_grace_period_seconds = 120 # Production (slower starts)
```

### Target Group Health Checks

Configure in ALB module:
- Path: `/health/`
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2 checks
- Unhealthy threshold: 2 checks

## Debugging with ECS Exec

Enable SSH-like access to running containers:

```hcl
enable_execute_command = true  # Dev only
```

Then connect:
```bash
aws ecs execute-command \
  --cluster backend-booking-dev-cluster \
  --task <task-id> \
  --container backend-booking \
  --interactive \
  --command "/bin/bash"
```

## Network Configuration

### Private Subnet Deployment

For security, deploy tasks in private subnets:

```hcl
subnet_ids       = module.networking.private_subnet_ids
assign_public_ip = false  # No public IP needed
```

Tasks reach internet via NAT Gateway (if enabled).

### Security Groups

Typical configuration:

```hcl
# ECS Tasks Security Group
resource "aws_security_group" "ecs_tasks" {
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Monitoring

### CloudWatch Dashboard

Automatically created when auto-scaling is enabled:
- CPU/Memory utilization
- Task count (desired, running, pending)
- Deployment status
- Error rates

### CloudWatch Alarms

Add custom alarms:

```hcl
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.service_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  
  dimensions = {
    ServiceName = module.app_service.service_name
    ClusterName = var.cluster_name
  }
}
```

## Cost Optimization

### Development Environment
- Single task (no redundancy)
- No auto-scaling
- Fargate Spot for 70% savings
- ~$10-15/month

### Production Environment
- Multiple tasks for high availability
- Auto-scaling based on load
- Regular Fargate for reliability
- ~$50-200/month depending on scale

## Common Issues and Solutions

### Tasks Not Starting

**Check:**
1. Task definition has correct image
2. Container health checks passing
3. Security groups allow traffic
4. Subnets have internet access (for image pull)
5. IAM roles have necessary permissions

### Tasks Constantly Restarting

**Solutions:**
- Increase `health_check_grace_period_seconds`
- Check application startup time
- Verify health check endpoint returns 200
- Review CloudWatch logs for errors

### Auto-scaling Not Working

**Verify:**
- Auto-scaling is enabled
- Metrics are being published
- Thresholds are appropriate
- Cooldown periods aren't too long

### Deployment Failures

**Check:**
- New task definition is valid
- Container image exists in ECR
- Resource limits are appropriate
- Health checks are configured correctly

## Outputs

| Output | Description |
|--------|-------------|
| `service_id` | ARN of the ECS service |
| `service_name` | Name of the service |
| `service_cluster` | Cluster ARN |
| `service_desired_count` | Number of desired tasks |
| `autoscaling_target_id` | Auto-scaling target ID |
| `cpu_scaling_policy_arn` | CPU scaling policy ARN |
| `memory_scaling_policy_arn` | Memory scaling policy ARN |
| `cloudwatch_dashboard_arn` | Dashboard ARN |

## Dependencies

This module requires:
- ECS Cluster (from `ecs-cluster` module)
- Task Definition (from `ecs-task-definition` module)
- VPC and Subnets (from `networking` module)
- Security Groups
- Target Group (from `alb` module) if using load balancer

## Future Enhancements

1. **Blue/Green Deployments** via CodeDeploy
2. **Canary Deployments** with traffic shifting
3. **Custom Metrics** scaling (e.g., queue depth)
4. **Service Mesh** integration (App Mesh)
5. **Multi-region** deployment support