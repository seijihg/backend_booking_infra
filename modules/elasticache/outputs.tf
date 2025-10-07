# ElastiCache Redis Module Outputs - Simplified

# Primary Connection Information
output "redis_url" {
  description = "Redis connection URL (use this in Django REDIS_URL environment variable)"
  value       = aws_ssm_parameter.redis_url.value
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis primary endpoint address"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port (default: 6379)"
  value       = 6379
}

# Parameter Store Path (for ECS task definitions)
output "parameter_store_path" {
  description = "Parameter Store path for Redis URL (use in ECS secrets)"
  value       = aws_ssm_parameter.redis_url.name
}

# Cluster Information
output "cluster_id" {
  description = "Redis cluster ID"
  value       = aws_elasticache_replication_group.redis.id
}

output "cluster_arn" {
  description = "Redis cluster ARN"
  value       = aws_elasticache_replication_group.redis.arn
}

# Engine Details
output "engine_version" {
  description = "Actual Redis engine version being used"
  value       = aws_elasticache_replication_group.redis.engine_version_actual
}
