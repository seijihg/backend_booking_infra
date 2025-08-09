output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "The ID of the first public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_2_id" {
  description = "The ID of the second public subnet"
  value       = aws_subnet.public_2.id
}

output "public_subnet_ids" {
  description = "List of all public subnet IDs"
  value       = [aws_subnet.public.id, aws_subnet.public_2.id]
}

output "public_subnet_cidr" {
  description = "The CIDR block of the first public subnet"
  value       = aws_subnet.public.cidr_block
}

output "public_subnet_2_cidr" {
  description = "The CIDR block of the second public subnet"
  value       = aws_subnet.public_2.cidr_block
}

output "private_subnet_id" {
  description = "The ID of the first private subnet"
  value       = aws_subnet.private.id
}

output "private_subnet_2_id" {
  description = "The ID of the second private subnet"
  value       = aws_subnet.private_2.id
}

output "private_subnet_ids" {
  description = "List of all private subnet IDs"
  value       = [aws_subnet.private.id, aws_subnet.private_2.id]
}

output "private_subnet_cidr" {
  description = "The CIDR block of the first private subnet"
  value       = aws_subnet.private.cidr_block
}

output "private_subnet_2_cidr" {
  description = "The CIDR block of the second private subnet"
  value       = aws_subnet.private_2.cidr_block
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway (if enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_eip" {
  description = "The Elastic IP of the NAT Gateway (if enabled)"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private.id
}

output "availability_zones" {
  description = "The availability zones used for the subnets"
  value       = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
}

output "availability_zone" {
  description = "The first availability zone (for backward compatibility)"
  value       = data.aws_availability_zones.available.names[0]
}

output "vpc_endpoints_sg_id" {
  description = "The ID of the security group for VPC endpoints (if enabled)"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

output "s3_endpoint_id" {
  description = "The ID of the S3 VPC endpoint (if enabled)"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
}