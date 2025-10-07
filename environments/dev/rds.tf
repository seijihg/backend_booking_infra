# RDS PostgreSQL Database Module
module "rds" {
  source = "../../modules/rds"

  app_name    = var.app_name
  environment = var.environment
  vpc_id      = module.networking.vpc_id

  # Use both private subnets for RDS subnet group (required by AWS)
  subnet_ids = module.networking.private_subnet_ids

  # Allow access from ECS tasks
  security_group_ids = [aws_security_group.ecs_tasks.id]

  # Database configuration
  # RDS requires alphanumeric only (no hyphens or underscores in db_name)
  db_name     = "${replace(var.app_name, "-", "")}${var.environment}"   # Results in "backendbookingdev"
  db_username = "${replace(var.app_name, "-", "_")}_${var.environment}" # Username can have underscores
  db_password = var.database_password # Must be provided in terraform.tfvars

  # Dev environment settings (cost-optimized)
  instance_class        = "db.t3.micro" # Free tier eligible
  allocated_storage     = 20
  max_allocated_storage = 0     # Disable autoscaling for dev
  multi_az              = false # Single AZ for dev
  deletion_protection   = false # Allow deletion in dev

  # Backup configuration (minimal for dev)
  backup_retention_period = 1    # Keep backups for 1 day only
  skip_final_snapshot     = true # Don't create snapshot on deletion

  # Monitoring (disabled for dev to save costs)
  monitoring_interval          = 0     # Disabled
  performance_insights_enabled = false # Disabled

  # Parameter Store integration
  parameter_store_path   = "/backend-booking/${var.environment}/database"
  update_parameter_store = true # Automatically update Parameter Store

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }

  # Ensure VPC endpoints are ready before creating RDS
  depends_on = [module.vpc_endpoints]
}
