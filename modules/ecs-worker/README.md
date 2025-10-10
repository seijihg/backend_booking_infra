# ECS Worker Module

Cost-optimized ECS Fargate module for running Dramatiq background workers with minimal resources and no auto-scaling.

## Features

- **Minimal Resources**: 256 CPU (0.25 vCPU) and 512 MB memory by default
- **Fargate Spot**: 70% cost savings with Spot instances (enabled by default)
- **Fixed Scaling**: No auto-scaling to keep costs predictable
- **Shared Infrastructure**: Uses same VPC, security groups, and secrets as web tasks
- **Graceful Shutdown**: 2-minute timeout for workers to finish current tasks
- **Optional Monitoring**: CloudWatch alarms without auto-scaling actions

## Usage

```hcl
module "dramatiq_worker" {
  source = "./modules/ecs-worker"

  # Basic Configuration
  app_name     = "backend-booking"
  environment  = "dev"
  aws_region   = "eu-west-2"

  # ECS Cluster
  ecs_cluster_id   = module.ecs_cluster.cluster_id
  ecs_cluster_name = module.ecs_cluster.cluster_name

  # Container
  ecr_repository_url = module.ecr.repository_url
  image_tag          = "latest"

  # Worker Settings (minimal for cost)
  worker_count       = 1      # Single worker
  worker_cpu         = "256"  # 0.25 vCPU
  worker_memory      = "512"  # 512 MB
  worker_concurrency = 2      # 2 threads per worker
  worker_queues      = "default,notifications,bookings"

  # Network
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_ids = [module.networking.ecs_security_group_id]

  # Secrets (same as web tasks)
  secrets_from_parameter_store = [
    {
      name      = "DJANGO_SECRET_KEY"
      valueFrom = "/backend-booking/${var.environment}/app/django-secret-key"
    },
    {
      name      = "DATABASE_URL"
      valueFrom = "/backend-booking/${var.environment}/database/url"
    },
    {
      name      = "REDIS_URL"
      valueFrom = "/backend-booking/${var.environment}/redis/url"
    }
  ]

  # Cost Optimization
  use_fargate_spot = true  # Use Spot instances
  log_retention_days = 7   # Minimal log retention

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Cost Breakdown

### Development Environment
- **Fargate Spot (256 CPU, 512 MB)**: ~$3-5/month
- **CloudWatch Logs**: ~$1/month
- **Total**: ~$4-6/month

### Production Environment (if scaling up)
- **2 workers (512 CPU, 1024 MB each)**: ~$20-30/month
- **CloudWatch Logs**: ~$3/month
- **Total**: ~$23-33/month

## Worker Resource Sizing Guide

| Use Case | CPU | Memory | Concurrency | Monthly Cost |
|----------|-----|--------|-------------|--------------|
| Light tasks (notifications) | 256 | 512 MB | 2 | ~$4-6 |
| Standard tasks (bookings) | 512 | 1024 MB | 4 | ~$10-15 |
| Heavy tasks (reports) | 1024 | 2048 MB | 8 | ~$20-30 |

## Queue Configuration

The worker processes these queues by default:
- `default`: General background tasks
- `notifications`: SMS and email sending
- `bookings`: Booking processing and updates
- `reports`: Heavy report generation (if needed)

## Monitoring

Optional CloudWatch alarms (disabled by default):
- CPU utilization > 80%
- Memory utilization > 80%

Enable monitoring with:
```hcl
enable_monitoring_alarms = true
alarm_notification_arns  = [aws_sns_topic.alerts.arn]
```

## Scaling Strategies

While this module doesn't include auto-scaling, you can manually scale:

```hcl
# Increase worker count during busy periods
worker_count = 2  # or 3, 4, etc.

# Increase resources for heavier workloads
worker_cpu    = "512"   # 0.5 vCPU
worker_memory = "1024"   # 1 GB
```

## Fargate Spot Considerations

Using Fargate Spot (enabled by default):
- **Pros**: 70% cost savings
- **Cons**: Tasks may be interrupted with 2-minute warning
- **Best for**: Non-critical background jobs
- **Disable for critical tasks**: `use_fargate_spot = false`

## Graceful Shutdown

Workers have 120 seconds to complete current tasks before termination. Ensure your Dramatiq tasks:
1. Are idempotent (safe to retry)
2. Complete within 2 minutes
3. Handle SIGTERM gracefully

## Troubleshooting

### Workers not processing tasks
1. Check CloudWatch logs: `/ecs/backend-booking-dev-worker`
2. Verify Redis connectivity
3. Ensure correct queue names in `WORKER_QUEUES`

### High CPU/Memory usage
1. Reduce `worker_concurrency`
2. Increase `worker_cpu` and `worker_memory`
3. Add more workers with `worker_count`

### Tasks being interrupted (Spot)
1. Disable Spot: `use_fargate_spot = false`
2. Or ensure tasks are idempotent and retriable