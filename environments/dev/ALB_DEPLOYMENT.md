# Application Load Balancer Deployment Guide

## Overview

The Application Load Balancer (ALB) has been successfully integrated into the dev environment infrastructure. This document provides details on the ALB configuration and how to use it.

## Current Configuration

### ALB Module Integration
```hcl
module "alb" {
  source = "../../modules/alb"
  
  # Deployed in public subnet for internet access
  public_subnet_ids = [module.networking.public_subnet_id]
  
  # Target configuration for Django on ECS
  target_port = 8000
  target_type = "ip"  # Required for Fargate
  
  # Health checks
  health_check_path = "/health/"
  health_check_interval = 30
}
```

## Architecture

```
Internet Traffic
       ↓
   [ALB - Public Subnet]
       ↓
   Target Group
       ↓
[ECS Tasks - Private Subnet]
    (When deployed)
```

## Key Features

### ✅ Implemented
- **Internet-facing ALB** in public subnet
- **Target Group** configured for ECS Fargate (`ip` target type)
- **Health Checks** on `/health/` endpoint
- **HTTP Listener** on port 80
- **CloudWatch Alarms** for monitoring
- **Proper Security Groups** configured

### 🔄 Ready for Future Implementation
- **HTTPS Support**: Add certificate ARN when available
- **ECS Integration**: Target group ready for ECS service attachment
- **Custom Domain**: Can add Route53 alias when domain is ready
- **WAF Protection**: Can attach WAF ACL for security

## Accessing the ALB

After deployment, the ALB will be accessible at:

```bash
# Get ALB DNS name
terraform output alb_url

# Example output:
# http://backend-booking-dev-alb-123456789.eu-west-2.elb.amazonaws.com
```

## Health Check Configuration

The ALB performs health checks with these settings:

| Setting | Value | Purpose |
|---------|-------|---------|
| Path | `/health/` | Django health endpoint |
| Interval | 30 seconds | Time between checks |
| Timeout | 5 seconds | Response timeout |
| Healthy Threshold | 2 | Consecutive successes |
| Unhealthy Threshold | 2 | Consecutive failures |
| Success Code | 200 | Expected response |

## Security Configuration

### ALB Security Group
The ALB uses a dedicated security group (`aws_security_group.alb`) that:
- Allows inbound HTTP (80) from anywhere
- Allows inbound HTTPS (443) from anywhere (when enabled)
- Allows all outbound traffic to reach ECS tasks

### Target Communication
- ALB → ECS Tasks: Port 8000 (Django application)
- Security group rules ensure only ALB can reach ECS tasks

## Cost Optimization for Dev

The dev environment configuration is optimized for cost:
- **Single AZ**: Using one availability zone (acceptable for dev)
- **No Access Logs**: Disabled to save S3 costs
- **Shorter Deregistration**: 15 seconds (vs 30 for prod)
- **No Deletion Protection**: Can be easily destroyed
- **Relaxed Alarms**: Higher thresholds for dev environment

Estimated monthly cost: ~$20-25

## Next Steps

### 1. Add ECS Service (When Docker Image is Ready)
```hcl
resource "aws_ecs_service" "app" {
  # ... other config ...
  
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "backend-booking"
    container_port   = 8000
  }
}
```

### 2. Enable HTTPS (Optional)
1. Create ACM certificate for your domain
2. Add `certificate_arn` to ALB module
3. ALB will automatically redirect HTTP to HTTPS

### 3. Add Custom Domain (Optional)
```hcl
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
```

## Testing the ALB

Once ECS tasks are deployed:

```bash
# Test health endpoint
curl http://<alb-dns-name>/health/

# Expected response
{"status": "healthy"}

# Test application
curl http://<alb-dns-name>/api/v1/status
```

## Monitoring

### CloudWatch Metrics
Monitor these key metrics:
- `TargetResponseTime`: Should be < 3 seconds
- `UnHealthyHostCount`: Should be 0
- `HTTPCode_Target_5XX_Count`: Should be minimal

### Viewing Metrics
```bash
# AWS CLI
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/backend-booking-dev-alb/* \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

## Troubleshooting

### ALB Not Accessible
1. Check ALB is in public subnet
2. Verify Internet Gateway is attached
3. Check security group allows inbound traffic
4. Ensure route table has 0.0.0.0/0 → IGW

### Unhealthy Targets
1. ECS tasks must be running
2. Health check path must return 200
3. Security groups must allow ALB → ECS communication
4. Container must be listening on port 8000

### 504 Gateway Timeout
1. Increase health check timeout
2. Check ECS task performance
3. Verify network connectivity

## Terraform Commands

```bash
# Deploy ALB
cd environments/dev
terraform plan
terraform apply

# Get ALB URL
terraform output alb_url

# Destroy ALB (if needed)
terraform destroy -target=module.alb
```

## Module Location

The ALB module is located at: `modules/alb/`

Key files:
- `main.tf`: ALB, target group, listeners
- `variables.tf`: Configuration options
- `outputs.tf`: DNS name, ARNs, etc.
- `README.md`: Complete module documentation