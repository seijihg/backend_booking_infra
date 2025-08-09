# VPC Endpoints Module

This module creates VPC Endpoints to allow resources in private subnets to access AWS services without requiring a NAT Gateway or Internet Gateway.

## Purpose

VPC Endpoints provide private connectivity between your VPC and AWS services. This module eliminates the need for a NAT Gateway ($45/month) by creating private endpoints for essential AWS services.

## Architecture

```
Private Subnet (ECS Tasks)
    ↓
VPC Endpoints (Private IPs)
    ├── SSM Parameter Store
    ├── ECR (Docker Registry)
    ├── S3 (ECR Layers)
    └── CloudWatch Logs
```

## Cost Comparison

### NAT Gateway Approach
- NAT Gateway: ~$45/month
- Data transfer: $0.045/GB
- Total: ~$50-100/month depending on usage

### VPC Endpoints Approach
- S3 Gateway Endpoint: FREE
- Interface Endpoints: ~$0.01/hour each (~$7.20/month each)
- Total: ~$30-40/month for all endpoints
- **Savings: ~$10-60/month**

## Required Endpoints

### For ECS Fargate with Parameter Store:

1. **SSM Endpoints** (3 required):
   - `com.amazonaws.region.ssm` - Parameter Store access
   - `com.amazonaws.region.ssmmessages` - Session Manager
   - `com.amazonaws.region.ec2messages` - ECS agent communication

2. **ECR Endpoints** (2 required):
   - `com.amazonaws.region.ecr.api` - ECR API operations
   - `com.amazonaws.region.ecr.dkr` - Docker registry operations

3. **S3 Endpoint** (1 required):
   - `com.amazonaws.region.s3` - ECR image layers stored in S3

4. **CloudWatch Logs Endpoint** (1 required):
   - `com.amazonaws.region.logs` - Container logs

## Usage

```hcl
module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"

  vpc_id     = module.networking.vpc_id
  vpc_cidr   = module.networking.vpc_cidr
  app_name   = var.app_name
  environment = var.environment
  aws_region  = var.aws_region
  
  # Subnets and route tables
  private_subnet_ids      = [module.networking.private_subnet_id]
  private_route_table_ids = [module.networking.private_route_table_id]
  
  # Security groups that need access
  security_group_ids = [
    aws_security_group.ecs_tasks.id
  ]
  
  # Enable required endpoints
  enable_ssm_endpoints    = true
  enable_ecr_endpoints    = true
  enable_s3_endpoint      = true
  enable_logs_endpoint    = true
  
  tags = {
    Environment = var.environment
    Project     = var.app_name
  }
}
```

## Security Considerations

### Security Group Rules
The module creates a dedicated security group for VPC endpoints that:
- Allows HTTPS (port 443) from the VPC CIDR
- Allows HTTPS from specified security groups (like ECS tasks)
- Blocks all other inbound traffic

### Private DNS
All interface endpoints have private DNS enabled, which means:
- AWS service calls automatically route through the VPC endpoint
- No application changes required
- DNS resolution returns private IPs within your VPC

## Troubleshooting

### ECS Tasks Still Can't Pull Images
1. Verify all ECR endpoints are created (api and dkr)
2. Check S3 endpoint is attached to private route table
3. Ensure security group allows port 443

### Parameter Store Access Issues
1. Verify all three SSM endpoints exist (ssm, ssmmessages, ec2messages)
2. Check security group allows ECS tasks to reach endpoints
3. Verify private DNS is enabled

### CloudWatch Logs Not Working
1. Ensure logs endpoint is created
2. Check IAM role has CloudWatch permissions
3. Verify security group rules

## Monitoring

Monitor endpoint usage in CloudWatch:
- Bytes processed per endpoint
- Number of connections
- Error rates

## Cost Optimization

### Dev Environment
Consider using only essential endpoints:
- Skip `secretsmanager` if using Parameter Store
- Can temporarily disable `logs` endpoint for testing

### Production Environment
All endpoints recommended for reliability:
- Prevents dependency on internet connectivity
- Improves security posture
- Reduces latency

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_endpoints_security_group_id` | Security group for endpoints |
| `s3_endpoint_id` | S3 gateway endpoint ID |
| `ssm_endpoint_id` | SSM interface endpoint ID |
| `ecr_api_endpoint_id` | ECR API endpoint ID |
| `ecr_dkr_endpoint_id` | ECR Docker endpoint ID |
| `logs_endpoint_id` | CloudWatch Logs endpoint ID |

## Important Notes

1. **One-time Setup**: VPC endpoints are created once per VPC
2. **No Ongoing Maintenance**: Endpoints are fully managed by AWS
3. **Regional Service**: Endpoints are region-specific
4. **Cost Effective**: Cheaper than NAT Gateway for most workloads
5. **Security Benefit**: Traffic never leaves AWS network