# RDS Module Outputs

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "The database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "The master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_password" {
  description = "The master password"
  value       = local.create_random_password ? random_password.db_password[0].result : var.db_password
  sensitive   = true
}

output "db_security_group_id" {
  description = "The security group ID for the RDS instance"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "The DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "db_parameter_group_name" {
  description = "The DB parameter group name"
  value       = aws_db_parameter_group.main.name
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.main.status
}

output "db_instance_class" {
  description = "The RDS instance class"
  value       = aws_db_instance.main.instance_class
}

output "db_allocated_storage" {
  description = "The allocated storage in GB"
  value       = aws_db_instance.main.allocated_storage
}

output "db_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = aws_db_instance.main.availability_zone
}

output "db_multi_az" {
  description = "If the RDS instance is multi-AZ"
  value       = aws_db_instance.main.multi_az
}

output "db_backup_retention_period" {
  description = "The backup retention period"
  value       = aws_db_instance.main.backup_retention_period
}

output "db_backup_window" {
  description = "The backup window"
  value       = aws_db_instance.main.backup_window
}

output "db_maintenance_window" {
  description = "The maintenance window"
  value       = aws_db_instance.main.maintenance_window
}

# Connection string for applications
output "db_connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${aws_db_instance.main.username}:${local.create_random_password ? random_password.db_password[0].result : var.db_password}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

# Django-specific DATABASE_URL format
output "django_database_url" {
  description = "Django DATABASE_URL format"
  value       = "postgres://${aws_db_instance.main.username}:${local.create_random_password ? random_password.db_password[0].result : var.db_password}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

# Parameter Store paths (if updated)
output "parameter_store_paths" {
  description = "Parameter Store paths for database configuration"
  value = var.update_parameter_store ? {
    host     = "${local.parameter_store_path}/host"
    port     = "${local.parameter_store_path}/port"
    name     = "${local.parameter_store_path}/name"
    username = "${local.parameter_store_path}/username"
    password = "${local.parameter_store_path}/password"
  } : null
}