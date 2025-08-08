# Application Load Balancer (ALB) Module

This module creates an Application Load Balancer with target groups, listeners, health checks, and optional SSL/TLS support.

## Architecture

```
Internet
    ↓
Application Load Balancer (Public Subnets)
    ├── HTTP Listener (Port 80)
    │   └── Redirect to HTTPS (if SSL enabled)
    ├── HTTPS Listener (Port 443) [Optional]
    │   └── SSL/TLS Termination
    └── Target Group
        ├── Health Checks
        └── ECS Tasks (Private Subnets)
```

## Features

- **Internet-facing ALB** in public subnets
- **Target group** with configurable health checks
- **HTTP listener** with optional HTTPS redirect
- **HTTPS listener** with SSL/TLS termination (optional)
- **CloudWatch alarms** for monitoring
- **WAF integration** (optional)
- **Access logs** to S3 (optional)
- **Sticky sessions** support (optional)

## Usage

### Basic HTTP Configuration

```hcl
module "alb" {
  source = "./modules/alb"

  app_name    = "backend-booking"
  environment = "dev"
  
  # Networking
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_group_id = aws_security_group.alb.id
  
  # Target configuration
  target_port     = 8000
  target_protocol = "HTTP"
  target_type     = "ip"  # For ECS Fargate
  
  # Health check
  health_check_path     = "/health/"
  health_check_interval = 30
  health_check_matcher  = "200"
  
  tags = {
    Environment = "dev"
    Project     = "Backend Booking"
  }
}
```

### HTTPS Configuration with SSL Certificate

```hcl
module "alb" {
  source = "./modules/alb"

  app_name    = "backend-booking"
  environment = "prod"
  
  # Networking
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_group_id = aws_security_group.alb.id
  
  # SSL Certificate
  certificate_arn = aws_acm_certificate.main.arn
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  
  # Enable protection for production
  enable_deletion_protection = true
  
  # Access logs
  enable_access_logs = true
  access_logs_bucket = aws_s3_bucket.logs.id
  access_logs_prefix = "alb"
  
  # Monitoring
  enable_alarms         = true
  alarm_actions        = [aws_sns_topic.alerts.arn]
  response_time_threshold = 2
  error_rate_threshold    = 50
  
  tags = {
    Environment = "prod"
    Project     = "Backend Booking"
  }
}
```

### With Sticky Sessions

```hcl
module "alb" {
  source = "./modules/alb"
  
  # ... other configuration ...
  
  # Enable sticky sessions
  enable_stickiness   = true
  stickiness_duration = 3600  # 1 hour
}
```

## Integration with ECS

After creating the ALB, use the target group ARN in your ECS service:

```hcl
resource "aws_ecs_service" "app" {
  name            = "my-service"
  cluster         = module.ecs_cluster.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "my-app"
    container_port   = 8000
  }
  
  # Important: Wait for ALB before starting service
  depends_on = [module.alb]
}
```

## Health Checks

The module configures health checks with sensible defaults:

| Parameter | Default | Description |
|-----------|---------|-------------|
| Path | `/health/` | Endpoint to check |
| Interval | 30 seconds | Time between checks |
| Timeout | 5 seconds | Time to wait for response |
| Healthy Threshold | 2 | Consecutive successes needed |
| Unhealthy Threshold | 2 | Consecutive failures before unhealthy |
| Matcher | 200 | Expected HTTP response code |

## SSL/TLS Configuration

### Creating an ACM Certificate

```hcl
resource "aws_acm_certificate" "main" {
  domain_name       = "api.example.com"
  validation_method = "DNS"
  
  subject_alternative_names = [
    "*.api.example.com"
  ]
  
  lifecycle {
    create_before_destroy = true
  }
}
```

### SSL Policies

Common SSL policies:
- `ELBSecurityPolicy-TLS-1-2-2017-01` - TLS 1.2 only (default)
- `ELBSecurityPolicy-TLS-1-2-Ext-2018-06` - TLS 1.2 with additional ciphers
- `ELBSecurityPolicy-FS-1-2-Res-2019-08` - TLS 1.2+ with forward secrecy

## Monitoring

### CloudWatch Metrics

The module creates alarms for:
- **Response Time**: Average target response time
- **Unhealthy Hosts**: Number of unhealthy targets
- **5xx Errors**: Server error rate

### Access Logs

Enable access logs to analyze traffic patterns:

```hcl
enable_access_logs = true
access_logs_bucket = "my-logs-bucket"
access_logs_prefix = "alb/prod"
```

Log format includes:
- Request timestamp
- Client IP and port
- Target IP and port
- Request processing time
- HTTP status code
- Request method and URI

## Security

### Security Group Example

```hcl
resource "aws_security_group" "alb" {
  name_prefix = "alb-"
  vpc_id      = module.networking.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### WAF Integration

Protect your ALB with AWS WAF:

```hcl
waf_acl_arn = aws_wafv2_web_acl.main.arn
```

## Cost Optimization

### Development Environment
- Single AZ deployment acceptable
- Disable access logs
- Shorter deregistration delay (10-15 seconds)
- No deletion protection

### Production Environment
- Multi-AZ deployment required
- Enable access logs for compliance
- Standard deregistration delay (30 seconds)
- Enable deletion protection

### Estimated Costs
- **ALB**: ~$0.025/hour ($18/month)
- **LCU**: ~$0.008/LCU-hour (varies with traffic)
- **Data Transfer**: $0.01/GB processed
- **Total**: ~$20-50/month for moderate traffic

## Outputs

| Output | Description | Use Case |
|--------|-------------|----------|
| `alb_dns_name` | DNS name of the ALB | Direct access or CNAME |
| `alb_zone_id` | Zone ID for Route53 | Alias records |
| `target_group_arn` | Target group ARN | ECS service configuration |
| `alb_url` | Full HTTP URL | Testing and access |

## Troubleshooting

### Common Issues

1. **Unhealthy targets**
   - Check security groups allow traffic
   - Verify health check path returns 200
   - Ensure ECS tasks are running

2. **504 Gateway Timeout**
   - Increase target response timeout
   - Check backend application performance
   - Verify network connectivity

3. **SSL certificate validation failed**
   - Ensure DNS validation records are created
   - Wait for certificate validation (can take 30+ minutes)

4. **Access denied from internet**
   - Verify ALB is in public subnets
   - Check Internet Gateway is attached
   - Review security group rules