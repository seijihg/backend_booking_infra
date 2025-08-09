# Outputs for Development Environment

# Account Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.id
}

# VPC and Networking Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs for ALB (2 AZs)"
  value       = module.networking.public_subnet_ids
}

output "public_subnet_id" {
  description = "First public subnet ID (for backward compatibility)"
  value       = module.networking.public_subnet_id
}

output "private_subnet_id" {
  description = "Private subnet ID for ECS tasks and databases"
  value       = module.networking.private_subnet_id
}

output "availability_zone" {
  description = "The availability zone used for subnets"
  value       = module.networking.availability_zone
}

# Security Groups
output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS database"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "Security group ID for ElastiCache Redis"
  value       = aws_security_group.redis.id
}

# NAT Gateway Status (for cost awareness)
output "nat_gateway_enabled" {
  description = "Whether NAT Gateway is enabled (affects costs)"
  value       = module.networking.nat_gateway_id != null
}

output "estimated_nat_cost" {
  description = "Estimated monthly NAT Gateway cost if enabled"
  value       = module.networking.nat_gateway_id != null ? "$45/month" : "$0 (disabled)"
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}

# ECS Cluster Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

# IAM Role Outputs (for future task definitions)
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role (for pulling images and writing logs)"
  value       = module.ecs_cluster.task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role (for application permissions)"
  value       = module.ecs_cluster.task_role_arn
}

# CloudWatch Log Group
output "ecs_log_group_name" {
  description = "Name of the CloudWatch log group for ECS"
  value       = module.ecs_cluster.log_group_name
}

# ECS Task Definition Outputs
output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.app_task_definition.task_definition_arn
}

output "task_definition_family" {
  description = "Family of the ECS task definition"
  value       = module.app_task_definition.task_definition_family
}

output "task_definition_revision" {
  description = "Revision of the ECS task definition"
  value       = module.app_task_definition.task_definition_revision
}

# ECS Service Outputs
output "ecs_service_id" {
  description = "ARN that identifies the ECS service"
  value       = module.app_service.service_id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.app_service.service_name
}

output "ecs_service_desired_count" {
  description = "Number of running tasks"
  value       = module.app_service.service_desired_count
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (for Route53 alias records)"
  value       = module.alb.alb_zone_id
}

output "alb_url" {
  description = "URL to access the application"
  value       = module.alb.alb_url
}

output "target_group_arn" {
  description = "ARN of the target group for ALB"
  value       = module.alb.target_group_arn
}

output "target_group_name" {
  description = "Name of the target group"
  value       = module.alb.target_group_name
}

# Parameter Store Path Outputs
output "parameter_store_base_path" {
  description = "Base path for Parameter Store parameters"
  value       = "/backend-booking/${var.environment}"
}

output "parameter_store_common_path" {
  description = "Common path for shared Parameter Store parameters"
  value       = "/backend-booking/common"
}

# VPC Endpoints Outputs
output "vpc_endpoints_created" {
  description = "List of VPC endpoints created"
  value = {
    s3          = module.vpc_endpoints.s3_endpoint_id != null ? "✅ Created (Free!)" : "❌ Not created"
    ssm         = module.vpc_endpoints.ssm_endpoint_id != null ? "✅ Created" : "❌ Not created"
    ecr_api     = module.vpc_endpoints.ecr_api_endpoint_id != null ? "✅ Created" : "❌ Not created"
    ecr_docker  = module.vpc_endpoints.ecr_dkr_endpoint_id != null ? "✅ Created" : "❌ Not created"
    logs        = module.vpc_endpoints.logs_endpoint_id != null ? "✅ Created" : "❌ Not created"
  }
}

output "vpc_endpoints_monthly_cost" {
  description = "Estimated monthly cost for VPC endpoints"
  value       = "~$30-35/month (vs $45/month for NAT Gateway)"
}