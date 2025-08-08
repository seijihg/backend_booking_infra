# ECS Module

This module creates and manages an AWS ECS cluster with Fargate for running the Backend Booking Django application.

## Features

- **ECS Cluster** with CloudWatch Container Insights
- **Task Definitions** for application and database migrations
- **ECS Service** with rolling deployments and circuit breaker
- **Auto-scaling** based on CPU, memory, and request count
- **IAM Roles** for task execution and application permissions
- **Security Groups** for network isolation
- **CloudWatch** logging and alarms
- **PgBouncer** sidecar for database connection pooling
- **Optional Features**:
  - Fargate Spot support for cost optimization
  - EFS integration for persistent storage
  - Service discovery
  - ECS Exec for debugging

## Usage

```hcl
module "ecs" {
  source = "../../modules/ecs"

  # General
  app_name    = "backend-booking"
  environment = "prod"
  aws_region  = "us-east-1"
  tags        = local.common_tags

  # Networking
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.alb.security_group_id

  # Container Configuration
  ecr_repository_url = aws_ecr_repository.app.repository_url
  image_tag         = var.image_tag
  task_cpu          = "512"
  task_memory       = "1024"
  container_port    = 8000

  # Application Configuration
  allowed_hosts              = "api.example.com"
  s3_bucket_name            = module.s3.bucket_name
  s3_bucket_arn             = module.s3.bucket_arn
  cloudfront_distribution_id = module.cloudfront.distribution_id
  redis_url                 = module.redis.connection_url

  # Database Configuration
  database_host = module.rds.db_instance_address
  database_name = var.database_name

  # Secrets
  secrets_arns = [
    module.secrets.django_secret_arn,
    module.secrets.database_secret_arn,
    module.secrets.monitoring_secret_arn,
    module.secrets.twilio_secret_arn
  ]
  django_secret_arn     = module.secrets.django_secret_arn
  database_secret_arn   = module.secrets.database_secret_arn
  monitoring_secret_arn = module.secrets.monitoring_secret_arn
  twilio_secret_arn     = module.secrets.twilio_secret_arn

  # ECS Service
  desired_count    = 3
  target_group_arn = module.alb.target_group_arn

  # Auto Scaling
  min_capacity        = 2
  max_capacity        = 10
  cpu_target_value    = 70
  memory_target_value = 80

  # Monitoring
  alarm_actions      = [aws_sns_topic.alerts.arn]
  log_retention_days = 30

  # Optional: Enable Fargate Spot for dev environment
  enable_fargate_spot = var.environment == "dev"
  fargate_spot_weight = 4
}
```

## Task Definitions

### Application Task
The main task definition runs the Django application with:
- Environment variables for configuration
- Secrets from AWS Secrets Manager
- Health checks
- CloudWatch logging
- PgBouncer sidecar for connection pooling

### Migration Task
A separate task definition for running database migrations:
```bash
aws ecs run-task \
  --cluster backend-booking-prod-cluster \
  --task-definition backend-booking-prod-migrate \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}"
```

## Auto-scaling

The module configures three auto-scaling policies:

1. **CPU-based**: Scales when average CPU utilization exceeds 70%
2. **Memory-based**: Scales when average memory utilization exceeds 80%
3. **Request-based** (optional): Scales based on ALB request count per target

## Security

- Tasks run in private subnets without public IPs
- Security groups restrict traffic to ALB only
- IAM roles follow least-privilege principle
- Secrets are stored in AWS Secrets Manager
- Container images are pulled from private ECR

## Monitoring

### CloudWatch Alarms
- High CPU utilization (>80%)
- High memory utilization (>80%)
- Low running task count (<minimum)

### Logs
All container logs are sent to CloudWatch Logs with configurable retention.

## Cost Optimization

- **Fargate Spot**: Enable for dev/staging environments (up to 70% savings)
- **Right-sizing**: Monitor metrics and adjust task CPU/memory
- **Auto-scaling**: Scale down during low traffic periods

## Troubleshooting

### ECS Exec
Enable ECS Exec for debugging:
```hcl
enable_ecs_exec = true
```

Then connect to a running container:
```bash
aws ecs execute-command \
  --cluster backend-booking-prod-cluster \
  --task <task-id> \
  --container backend-booking \
  --interactive \
  --command "/bin/bash"
```

### Common Issues

1. **Task fails to start**: Check CloudWatch logs and verify secrets/environment variables
2. **Out of memory**: Increase task_memory or optimize application
3. **Cannot connect to database**: Verify security groups and PgBouncer configuration
4. **Slow deployments**: Adjust deployment_configuration parameters

## Inputs

See [variables.tf](./variables.tf) for all available inputs.

## Outputs

See [outputs.tf](./outputs.tf) for all available outputs.