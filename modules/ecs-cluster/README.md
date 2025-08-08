# ECS Cluster Module

This module creates a standalone ECS Fargate cluster without task definitions or services. It provides the foundational infrastructure for running containerized applications on AWS ECS.

## Purpose

This module is designed to:
- Create an ECS cluster with Fargate support
- Set up IAM roles for task execution and task roles
- Configure CloudWatch logging
- Optionally enable Container Insights and Service Discovery
- Support both regular Fargate and Fargate Spot for cost optimization

## Architecture

```
ECS Cluster
├── Fargate Capacity Providers
│   ├── FARGATE (regular)
│   └── FARGATE_SPOT (optional, cost-optimized)
├── IAM Roles
│   ├── Task Execution Role (for ECS agent)
│   └── Task Role (for application)
├── CloudWatch
│   ├── Log Group (/ecs/{app-name}-{env})
│   └── Container Insights (optional)
└── Service Discovery (optional)
    └── Private DNS Namespace
```

## Usage

### Basic Example

```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  app_name    = "backend-booking"
  environment = "dev"
  aws_region  = "us-east-1"
  vpc_id      = module.networking.vpc_id

  # Enable Container Insights for monitoring
  enable_container_insights = true

  # Log retention
  log_retention_days = 7

  tags = {
    Project = "Backend Booking"
    Owner   = "DevOps Team"
  }
}
```

### With Fargate Spot

```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  app_name    = "backend-booking"
  environment = "dev"
  aws_region  = "us-east-1"
  vpc_id      = module.networking.vpc_id

  # Enable Fargate Spot for cost savings
  enable_fargate_spot = true
  fargate_weight      = 1  # Regular Fargate
  fargate_spot_weight = 3  # Prefer Spot instances

  enable_container_insights = true
  log_retention_days       = 7

  tags = local.common_tags
}
```

### With Service Discovery

```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"

  app_name    = "backend-booking"
  environment = "prod"
  aws_region  = "us-east-1"
  vpc_id      = module.networking.vpc_id

  # Enable service discovery for inter-service communication
  enable_service_discovery = true

  # S3 bucket for application storage
  s3_bucket_arn = aws_s3_bucket.app_storage.arn

  # CloudWatch alarms
  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}
```

## Integration with Task Definitions

After creating the cluster, you can create task definitions and services that reference this cluster:

```hcl
# Example: Creating a task definition (in a separate module or resource)
resource "aws_ecs_task_definition" "app" {
  family                   = "my-app"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  
  # Use the roles from the cluster module
  execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn     = module.ecs_cluster.task_role_arn
  
  # ... container definitions ...
}

# Example: Creating a service
resource "aws_ecs_service" "app" {
  name            = "my-app-service"
  cluster         = module.ecs_cluster.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  
  # ... service configuration ...
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| app_name | Name of the application | string | - | yes |
| environment | Environment name (dev, staging, prod) | string | - | yes |
| aws_region | AWS region | string | "us-east-1" | no |
| vpc_id | VPC ID where the cluster will be deployed | string | - | yes |
| enable_container_insights | Enable CloudWatch Container Insights | bool | true | no |
| log_retention_days | CloudWatch log retention in days | number | 7 | no |
| enable_fargate_spot | Enable Fargate Spot for cost optimization | bool | false | no |
| fargate_weight | Weight for FARGATE capacity provider | number | 1 | no |
| fargate_base | Base tasks for FARGATE capacity provider | number | 1 | no |
| fargate_spot_weight | Weight for FARGATE_SPOT capacity provider | number | 2 | no |
| enable_service_discovery | Enable service discovery for the cluster | bool | false | no |
| s3_bucket_arn | ARN of S3 bucket for application storage | string | "" | no |
| alarm_actions | List of ARNs to notify when alarms trigger | list(string) | [] | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the ECS cluster |
| cluster_arn | The ARN of the ECS cluster |
| cluster_name | The name of the ECS cluster |
| task_execution_role_arn | ARN of the ECS task execution role |
| task_execution_role_name | Name of the ECS task execution role |
| task_role_arn | ARN of the ECS task role |
| task_role_name | Name of the ECS task role |
| log_group_name | Name of the CloudWatch log group for ECS |
| log_group_arn | ARN of the CloudWatch log group for ECS |
| service_discovery_namespace_id | ID of the service discovery namespace (if enabled) |
| service_discovery_namespace_arn | ARN of the service discovery namespace (if enabled) |
| service_discovery_namespace_name | Name of the service discovery namespace (if enabled) |
| capacity_providers | List of capacity providers associated with the cluster |

## IAM Roles

The module creates two IAM roles:

1. **Task Execution Role**: Used by ECS to pull container images and write logs
   - Permissions: ECR access, CloudWatch logs, SSM Parameter Store, KMS decryption

2. **Task Role**: Assumed by the running container tasks
   - Permissions: S3 access (if bucket ARN provided), CloudWatch metrics, X-Ray tracing

## Cost Optimization

### Fargate Spot
Enable Fargate Spot to save up to 70% on compute costs for fault-tolerant workloads:
```hcl
enable_fargate_spot = true
fargate_spot_weight = 3  # Prefer Spot over regular Fargate
```

### Log Retention
Adjust log retention to control CloudWatch costs:
```hcl
log_retention_days = 3  # For development
log_retention_days = 30 # For production
```

## Migration from Combined Module

If migrating from a module that included task definitions and services:

1. Deploy this cluster module first
2. Create separate modules for task definitions and services
3. Reference the cluster outputs in your task/service configurations
4. Gradually migrate existing workloads

## Security Considerations

- Task execution role has minimal permissions (pull images, write logs)
- Task role permissions are customizable based on application needs
- SSM Parameter Store access is scoped to environment-specific paths
- KMS decryption is limited to SSM service usage

## Future Enhancements

This module is designed to be extended with:
- ECR repository creation and lifecycle policies
- Task definition templates
- Service modules with ALB/NLB integration
- Blue/green deployment configurations
- Capacity provider strategies per service