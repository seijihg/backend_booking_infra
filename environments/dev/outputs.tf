# Outputs for Development Environment

# Account Information
output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
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

output "public_subnet_id" {
  description = "Public subnet ID for ALB and NAT Gateway"
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