# VPC Endpoints Module Outputs

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC endpoint (for security group rules)"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].prefix_list_id : null
}

output "ssm_endpoint_id" {
  description = "ID of the SSM VPC endpoint"
  value       = var.enable_ssm_endpoints ? aws_vpc_endpoint.ssm[0].id : null
}

output "ssmmessages_endpoint_id" {
  description = "ID of the SSM Messages VPC endpoint"
  value       = var.enable_ssm_endpoints ? aws_vpc_endpoint.ssmmessages[0].id : null
}

output "ec2messages_endpoint_id" {
  description = "ID of the EC2 Messages VPC endpoint"
  value       = var.enable_ssm_endpoints ? aws_vpc_endpoint.ec2messages[0].id : null
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = var.enable_ecr_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR Docker VPC endpoint"
  value       = var.enable_ecr_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

output "logs_endpoint_id" {
  description = "ID of the CloudWatch Logs VPC endpoint"
  value       = var.enable_logs_endpoint ? aws_vpc_endpoint.logs[0].id : null
}

output "secretsmanager_endpoint_id" {
  description = "ID of the Secrets Manager VPC endpoint"
  value       = var.enable_secrets_manager_endpoint ? aws_vpc_endpoint.secretsmanager[0].id : null
}

output "vpc_endpoint_dns_entries" {
  description = "DNS entries for all VPC endpoints"
  value = {
    ssm         = var.enable_ssm_endpoints ? aws_vpc_endpoint.ssm[0].dns_entry : []
    ssmmessages = var.enable_ssm_endpoints ? aws_vpc_endpoint.ssmmessages[0].dns_entry : []
    ec2messages = var.enable_ssm_endpoints ? aws_vpc_endpoint.ec2messages[0].dns_entry : []
    ecr_api     = var.enable_ecr_endpoints ? aws_vpc_endpoint.ecr_api[0].dns_entry : []
    ecr_dkr     = var.enable_ecr_endpoints ? aws_vpc_endpoint.ecr_dkr[0].dns_entry : []
    logs        = var.enable_logs_endpoint ? aws_vpc_endpoint.logs[0].dns_entry : []
  }
}