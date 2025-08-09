# RDS PostgreSQL Module

locals {
  instance_identifier    = var.instance_identifier != "" ? var.instance_identifier : "${var.app_name}-${var.environment}-db"
  final_snapshot_id      = var.final_snapshot_identifier != "" ? var.final_snapshot_identifier : "${local.instance_identifier}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  parameter_store_path   = var.parameter_store_path != "" ? var.parameter_store_path : "/${var.app_name}/${var.environment}/database"
  
  # Generate random password if not provided
  create_random_password = var.db_password == ""
}

# Generate random password if not provided
resource "random_password" "db_password" {
  count   = local.create_random_password ? 1 : 0
  length  = 32
  special = true
  # Exclude problematic characters for URLs and shells
  override_special = "!#$%&*()-_=+[]{}:?"
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.environment}-rds"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.app_name}-${var.environment}-rds-sg"
    }
  )
}

# Ingress rules for allowed security groups
resource "aws_security_group_rule" "rds_ingress" {
  for_each = toset(var.security_group_ids)

  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.rds.id
  description              = "PostgreSQL access from ${each.value}"
}

# Egress rule (required for RDS)
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${local.instance_identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${local.instance_identifier}-subnet-group"
    }
  )
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name        = "${local.instance_identifier}-params"
  family      = var.family
  description = "Custom parameter group for ${local.instance_identifier}"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"  # Static parameters require reboot
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.instance_identifier}-params"
    }
  )
}

# Enhanced Monitoring Role (if needed)
resource "aws_iam_role" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == "" ? 1 : 0

  name = "${local.instance_identifier}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == "" ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = local.instance_identifier

  # Engine
  engine         = "postgres"
  engine_version = var.engine_version

  # Credentials
  db_name  = var.db_name
  username = var.db_username
  password = local.create_random_password ? random_password.db_password[0].result : var.db_password
  port     = var.db_port

  # Instance
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id           = var.kms_key_id != "" ? var.kms_key_id : null

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible
  availability_zone      = var.multi_az ? null : var.availability_zone
  multi_az              = var.multi_az

  # Parameters
  parameter_group_name = aws_db_parameter_group.main.name

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshot_id
  copy_tags_to_snapshot  = var.copy_tags_to_snapshot

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn            = var.monitoring_interval > 0 ? (
    var.monitoring_role_arn != "" ? var.monitoring_role_arn : aws_iam_role.enhanced_monitoring[0].arn
  ) : null
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Other
  deletion_protection        = var.deletion_protection
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  tags = merge(
    var.tags,
    {
      Name        = local.instance_identifier
      Environment = var.environment
      Application = var.app_name
    }
  )

  lifecycle {
    ignore_changes = [password]  # Ignore password changes after creation
  }
}

# Store connection details in Parameter Store
resource "aws_ssm_parameter" "db_host" {
  count = var.update_parameter_store ? 1 : 0

  name        = "${local.parameter_store_path}/host"
  description = "RDS instance endpoint"
  type        = "String"
  value       = aws_db_instance.main.address
  overwrite   = true

  tags = var.tags
}

resource "aws_ssm_parameter" "db_port" {
  count = var.update_parameter_store ? 1 : 0

  name        = "${local.parameter_store_path}/port"
  description = "RDS instance port"
  type        = "String"
  value       = tostring(aws_db_instance.main.port)
  overwrite   = true

  tags = var.tags
}

resource "aws_ssm_parameter" "db_name" {
  count = var.update_parameter_store ? 1 : 0

  name        = "${local.parameter_store_path}/name"
  description = "Database name"
  type        = "String"
  value       = aws_db_instance.main.db_name
  overwrite   = true

  tags = var.tags
}

resource "aws_ssm_parameter" "db_username" {
  count = var.update_parameter_store ? 1 : 0

  name        = "${local.parameter_store_path}/username"
  description = "Database master username"
  type        = "String"
  value       = aws_db_instance.main.username
  overwrite   = true

  tags = var.tags
}

resource "aws_ssm_parameter" "db_password" {
  count = var.update_parameter_store ? 1 : 0

  name        = "${local.parameter_store_path}/password"
  description = "Database master password"
  type        = "SecureString"
  value       = local.create_random_password ? random_password.db_password[0].result : var.db_password
  overwrite   = true

  tags = var.tags
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  count = var.monitoring_interval > 0 ? 1 : 0

  alarm_name          = "${local.instance_identifier}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  count = var.monitoring_interval > 0 ? 1 : 0

  alarm_name          = "${local.instance_identifier}-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2147483648"  # 2GB in bytes
  alarm_description   = "This metric monitors RDS free storage"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  count = var.monitoring_interval > 0 ? 1 : 0

  alarm_name          = "${local.instance_identifier}-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "50"  # Adjust based on instance class
  alarm_description   = "This metric monitors RDS connection count"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = var.tags
}