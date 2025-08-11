# ECS Task Definition Module

This module creates an ECS Task Definition for running Django applications on AWS Fargate.

## Features

- **Django-optimized configuration** with environment variables and secrets
- **Parameter Store integration** for sensitive data
- **CloudWatch logging** for application logs
- **Health checks** for container monitoring
- **Flexible resource allocation** (CPU/Memory)
- **Optional integrations** (Twilio, S3, CloudFront)

## Architecture

```
Task Definition
├── Container: Django Application
│   ├── Image: ECR Repository
│   ├── Environment Variables
│   ├── Secrets from Parameter Store
│   ├── Port: 8000
│   └── Health Check: Removed (use ALB health checks)
├── Resources
│   ├── CPU: 512-4096
│   └── Memory: 1024-8192
└── Logging
    └── CloudWatch Logs
```

## Usage

### Basic Example

```hcl
module "task_definition" {
  source = "./modules/ecs-task-definition"

  app_name    = "backend-booking"
  environment = "dev"
  
  # Container configuration
  container_name  = "backend-booking"
  container_image = "826601724385.dkr.ecr.eu-west-2.amazonaws.com/backend-booking-dev:latest"
  container_port  = 8000
  
  # Resources
  task_cpu    = "512"
  task_memory = "1024"
  
  # IAM Roles (from ECS cluster module)
  execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn     = module.ecs_cluster.task_role_arn
  
  # Logging
  log_group_name = module.ecs_cluster.log_group_name
  
  # Django settings
  django_settings_module = "config.settings.production"
  allowed_hosts         = "*"
  debug_mode           = false
  
  tags = {
    Environment = "dev"
    Project     = "Backend Booking"
  }
}
```

### Production Example with All Features

```hcl
module "task_definition" {
  source = "./modules/ecs-task-definition"

  app_name    = "backend-booking"
  environment = "prod"
  
  # Container configuration
  container_name  = "backend-booking"
  container_image = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
  container_port  = 8000
  
  # Production resources
  task_cpu    = "1024"
  task_memory = "2048"
  
  # IAM Roles
  execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn     = module.ecs_cluster.task_role_arn
  
  # Logging
  log_group_name = module.ecs_cluster.log_group_name
  
  # Django settings
  django_settings_module = "config.settings.production"
  allowed_hosts         = "api.example.com"
  debug_mode           = false
  
  # Enable optional services
  enable_twilio              = true
  s3_bucket_name            = "my-static-bucket"
  cloudfront_distribution_id = "E1234567890ABC"
  
  # Additional environment variables
  environment_variables = {
    "CORS_ALLOWED_ORIGINS" = "https://example.com"
    "CELERY_BROKER_URL"    = "redis://redis.example.com:6379/0"
  }
  
  # Additional secrets
  secrets_from_parameter_store = {
    "SENTRY_DSN" = "/backend-booking/prod/app/sentry-dsn"
    "API_KEY"    = "/backend-booking/prod/app/api-key"
  }
  
  # Security hardening
  readonly_root_filesystem = true
  container_user          = "1000:1000"
  
  tags = {
    Environment = "prod"
    Project     = "Backend Booking"
  }
}
```

## Environment Variables

### Automatically Configured

| Variable | Description | Source |
|----------|-------------|--------|
| `DJANGO_SETTINGS_MODULE` | Django settings path | Variable |
| `ENVIRONMENT` | Current environment | Variable |
| `PORT` | Container port | Variable |
| `ALLOWED_HOSTS` | Django allowed hosts | Variable |
| `DEBUG` | Django debug mode | Variable |
| `PYTHONUNBUFFERED` | Python output buffering | Fixed: "1" |
| `DATABASE_ENGINE` | Database engine | Fixed: PostgreSQL |

### Secrets from Parameter Store

| Secret | Parameter Store Path | Required |
|--------|---------------------|----------|
| `DJANGO_SECRET_KEY` | `/backend-booking/{env}/app/django-secret-key` | Yes |
| `DATABASE_PASSWORD` | `/backend-booking/{env}/database/password` | Yes |
| `DATABASE_HOST` | `/backend-booking/{env}/database/host` | Yes |
| `DATABASE_NAME` | `/backend-booking/{env}/database/name` | Yes |
| `DATABASE_USER` | `/backend-booking/{env}/database/username` | Yes |
| `REDIS_HOST` | `/backend-booking/{env}/redis/host` | Yes |
| `TWILIO_*` | `/backend-booking/{env}/third-party/twilio-*` | Optional |

## Resource Allocation

### Fargate CPU/Memory Combinations

| CPU | Memory Options |
|-----|----------------|
| 256 | 512, 1024, 2048 |
| 512 | 1024-4096 (1GB increments) |
| 1024 | 2048-8192 (1GB increments) |
| 2048 | 4096-16384 (1GB increments) |
| 4096 | 8192-30720 (1GB increments) |

### Recommended Settings

- **Development**: 512 CPU, 1024 Memory
- **Staging**: 1024 CPU, 2048 Memory
- **Production**: 2048 CPU, 4096 Memory

## Health Checks

Container-level health checks have been **completely removed** from this module. 

**Why removed?**
- ALB target group health checks are more reliable and sufficient
- Container health checks add unnecessary overhead (CPU/memory for curl commands)
- Having both ALB and container health checks creates redundancy and confusion
- ALB health checks test actual HTTP endpoints, not just container status

**For health check configuration:**
- Configure health checks in the ALB module's target group settings
- ALB health checks support custom paths, intervals, thresholds, and HTTP status codes
- ECS will automatically replace unhealthy tasks based on ALB health check results

## Advanced Features

### Custom Command

Override the default container command:

```hcl
container_command = ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

### Mount EFS Volume

```hcl
volumes = [{
  name = "static-files"
  efs_volume_configuration = {
    file_system_id = aws_efs_file_system.static.id
    root_directory = "/static"
  }
}]

mount_points = [{
  sourceVolume  = "static-files"
  containerPath = "/app/static"
  readOnly      = false
}]
```

### Security Hardening

```hcl
# Read-only root filesystem
readonly_root_filesystem = true

# Run as non-root user
container_user = "1000:1000"

# Drop unnecessary Linux capabilities
enable_linux_parameters = true
linux_capabilities_drop = ["ALL"]
linux_capabilities_add = ["NET_BIND_SERVICE"]
```

## Integration with ECS Service

After creating the task definition, use it in an ECS service:

```hcl
resource "aws_ecs_service" "app" {
  name            = "backend-booking"
  cluster         = module.ecs_cluster.cluster_id
  task_definition = module.task_definition.task_definition_arn
  desired_count   = 2
  
  # ... rest of service configuration
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `task_definition_arn` | Full ARN with revision |
| `task_definition_family` | Task family name |
| `task_definition_revision` | Current revision number |
| `container_name` | Container name for service configuration |
| `container_port` | Container port for load balancer configuration |

## Troubleshooting

### Task Fails to Start

1. Check CloudWatch logs for errors
2. Verify image exists in ECR
3. Ensure Parameter Store values exist
4. Check IAM role permissions

### Out of Memory

- Increase `task_memory` value
- Check for memory leaks in application
- Enable memory monitoring

### Health Check Failures

Since container health checks are removed, troubleshoot via ALB:
- Verify the ALB target group health check path is correct
- Check the ALB target group health check settings in the ALB module
- Review ECS service logs for startup errors
- Check CloudWatch metrics for unhealthy target count
- Use ECS Exec to test the application endpoint directly