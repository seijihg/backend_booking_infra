# ElastiCache Redis Module - Simplified

locals {
  cluster_id = "${var.app_name}-${var.environment}-redis"
}

# Subnet group for ElastiCache
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.cluster_id}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${local.cluster_id}-subnet-group"
    }
  )
}

# Parameter Group for Redis configuration
resource "aws_elasticache_parameter_group" "redis" {
  name   = "${local.cluster_id}-params"
  family = "redis7"

  # Sensible defaults for session storage and caching
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.cluster_id}-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ElastiCache Replication Group (Redis Cluster)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = local.cluster_id
  description          = "Redis for ${var.app_name} ${var.environment}"

  # Engine configuration
  engine               = "redis"
  engine_version       = var.engine_version
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.redis.name

  # Node configuration
  node_type          = var.node_type
  num_cache_clusters = var.num_cache_nodes

  # Network configuration
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = var.security_group_ids

  # High availability (only for production)
  automatic_failover_enabled = var.multi_az_enabled
  multi_az_enabled           = var.multi_az_enabled

  # Backup configuration
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = "03:00-05:00"

  # Maintenance
  maintenance_window         = "sun:05:00-sun:07:00"
  auto_minor_version_upgrade = true

  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = var.enable_auth_token
  auth_token                 = var.enable_auth_token ? var.auth_token : null

  # Apply changes immediately in dev, during maintenance in prod
  apply_immediately = var.environment == "dev" ? true : false

  tags = merge(
    var.tags,
    {
      Name = local.cluster_id
    }
  )

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}

# Store Redis URL in Parameter Store for easy Django access
resource "aws_ssm_parameter" "redis_url" {
  name        = "/${var.app_name}/${var.environment}/redis/url"
  description = "Redis connection URL for Django"
  type        = "String"
  value       = var.enable_auth_token ? "rediss://:${var.auth_token}@${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379/0" : "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:6379/0"
  overwrite   = true  # Allow overwriting if parameter already exists

  tags = merge(
    var.tags,
    {
      Name = "${local.cluster_id}-url"
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [description]  # Don't recreate if only description changes
  }
}
