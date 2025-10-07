# ElastiCache Redis Module - Simplified

Dead-simple Redis module for Django applications. Just provide the required variables and you're ready to go.

## Why This Module?

- ✅ **Zero Config**: Sensible defaults for everything
- ✅ **One Connection String**: Single `REDIS_URL` environment variable
- ✅ **Django Ready**: Works out of the box with django-redis and Dramatiq
- ✅ **Production Path**: Easy upgrade from dev to production
- ✅ **Cost Optimized**: ~$12/month for development

## Quick Start

### 1. Add Module to Your Environment

```hcl
module "redis" {
  source = "../../modules/elasticache"

  # Required (5 variables)
  app_name           = "backend-booking"
  environment        = "dev"
  vpc_id             = module.networking.vpc_id
  subnet_ids         = [module.networking.private_subnet_id]
  security_group_ids = [aws_security_group.ecs_tasks.id]

  tags = {
    Environment = "dev"
  }
}
```

That's it! Everything else has sensible defaults.

### 2. Use in Django

The module automatically creates a Parameter Store entry at:
```
/backend-booking/dev/redis/url
```

In your ECS task definition:
```hcl
secrets = [
  {
    name      = "REDIS_URL"
    valueFrom = module.redis.parameter_store_path
  }
]
```

In Django:
```python
import os

REDIS_URL = os.environ['REDIS_URL']

# Cache
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
    }
}

# Sessions
SESSION_ENGINE = "django.contrib.sessions.backends.cache"

# Dramatiq
DRAMATIQ_BROKER = {
    "BROKER": "dramatiq.brokers.redis.RedisBroker",
    "OPTIONS": {"url": REDIS_URL},
}
```

Done! Your application can now use Redis for caching, sessions, and background jobs.

## Configuration

### Required Variables (5)

| Variable | Description | Example |
|----------|-------------|---------|
| `app_name` | Application name | `"backend-booking"` |
| `environment` | Environment | `"dev"` |
| `vpc_id` | VPC ID | `"vpc-123456"` |
| `subnet_ids` | Private subnet IDs | `[subnet-abc123]` |
| `security_group_ids` | Security groups that can access | `[sg-xyz789]` |

### Optional Variables (with smart defaults)

| Variable | Default | Production Recommendation |
|----------|---------|---------------------------|
| `node_type` | `cache.t3.micro` | `cache.t3.small` or higher |
| `num_cache_nodes` | `1` | `2` (for Multi-AZ) |
| `engine_version` | `7.1` | Latest stable |
| `multi_az_enabled` | `false` | `true` |
| `snapshot_retention_limit` | `0` | `5` (days) |
| `enable_auth_token` | `false` | `true` |
| `auth_token` | `""` | Strong random token |

## Outputs

| Output | Description |
|--------|-------------|
| `redis_url` | Full Redis connection URL (sensitive) |
| `parameter_store_path` | Path to use in ECS secrets |
| `redis_endpoint` | Redis endpoint address |
| `redis_port` | Redis port (6379) |
| `cluster_id` | Redis cluster ID |

## Upgrading to Production

When you're ready for production, just override the defaults:

```hcl
module "redis" {
  source = "../../modules/elasticache"

  # Same required variables
  app_name           = "backend-booking"
  environment        = "prod"
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.private_subnet_ids  # Multiple AZs
  security_group_ids = [aws_security_group.ecs_tasks.id]

  # Production overrides
  node_type                = "cache.t3.small"  # More memory
  num_cache_nodes          = 2                 # Primary + replica
  multi_az_enabled         = true              # High availability
  snapshot_retention_limit = 5                 # Daily backups
  enable_auth_token        = true              # Security
  auth_token               = var.redis_auth_token

  tags = {
    Environment = "prod"
  }
}
```

## What Gets Created

1. **Subnet Group**: For placing Redis in private subnets
2. **Parameter Group**: Optimized Redis settings (LRU eviction, connection timeout)
3. **Replication Group**: The actual Redis cluster
4. **Parameter Store Entry**: `/app-name/environment/redis/url` for easy access

Total: 4 resources

## Default Configuration

The module includes production-ready defaults:

- **Memory Policy**: `allkeys-lru` (evict least recently used when full)
- **Connection Timeout**: 300 seconds (close idle connections)
- **Encryption at Rest**: Enabled (AWS KMS)
- **Auto Minor Upgrades**: Enabled
- **Maintenance Window**: Sunday 05:00-07:00 UTC
- **Snapshot Window**: 03:00-05:00 UTC (if enabled)

## Security

- ✅ Deployed in private subnets (no public access)
- ✅ Encryption at rest enabled by default
- ✅ Only specified security groups can access
- ✅ TLS encryption available for production
- ✅ AUTH token support for production

## Cost

### Development
- `cache.t3.micro`: ~$12/month
- No backups
- Single node
- **Total**: ~$12/month

### Production (Recommended)
- `cache.t3.small` (2 nodes): ~$50/month
- 5-day backups: ~$1/month
- Multi-AZ: Included
- **Total**: ~$51/month

## Monitoring

Access CloudWatch metrics:
- CPUUtilization
- DatabaseMemoryUsagePercentage
- CurrConnections
- Evictions
- NetworkBytesIn/Out

## Troubleshooting

### Can't connect from Django

1. **Check security group**: Ensure ECS security group is in `security_group_ids`
2. **Check VPC**: Redis and ECS must be in same VPC
3. **Check URL**: Verify Parameter Store has the URL
4. **Check network**: Ensure private subnets have route to Redis

```bash
# Get Redis URL
aws ssm get-parameter --name /backend-booking/dev/redis/url

# Check security group
aws ec2 describe-security-group-rules --filter "Name=group-id,Values=<redis-sg>"

# Test from ECS container
aws ecs execute-command --cluster <cluster> --task <task> --interactive --command "/bin/bash"
python manage.py shell
>>> import redis, os
>>> r = redis.from_url(os.environ['REDIS_URL'])
>>> r.ping()
```

### High memory usage

Upgrade node type:
```hcl
node_type = "cache.t3.small"  # 3x more memory
```

### Need high availability

Enable Multi-AZ:
```hcl
num_cache_nodes  = 2
multi_az_enabled = true
```

## Examples

### Minimal Development Setup
```hcl
module "redis" {
  source             = "../../modules/elasticache"
  app_name           = "myapp"
  environment        = "dev"
  vpc_id             = "vpc-123"
  subnet_ids         = ["subnet-abc"]
  security_group_ids = ["sg-xyz"]
  tags               = { Environment = "dev" }
}
```

### Production with High Availability
```hcl
module "redis" {
  source             = "../../modules/elasticache"
  app_name           = "myapp"
  environment        = "prod"
  vpc_id             = "vpc-123"
  subnet_ids         = ["subnet-abc", "subnet-def"]  # Multiple AZs
  security_group_ids = ["sg-xyz"]

  node_type                = "cache.t3.small"
  num_cache_nodes          = 2
  multi_az_enabled         = true
  snapshot_retention_limit = 5
  enable_auth_token        = true
  auth_token               = var.redis_auth_token

  tags = { Environment = "prod" }
}
```

### Production with TLS and AUTH
```hcl
module "redis" {
  source             = "../../modules/elasticache"
  app_name           = "myapp"
  environment        = "prod"
  vpc_id             = "vpc-123"
  subnet_ids         = ["subnet-abc", "subnet-def"]
  security_group_ids = ["sg-xyz"]

  node_type         = "cache.t3.medium"
  num_cache_nodes   = 3  # Primary + 2 replicas
  multi_az_enabled  = true
  enable_auth_token = true
  auth_token        = random_password.redis_token.result

  tags = { Environment = "prod", Critical = "true" }
}

# Generate secure auth token
resource "random_password" "redis_token" {
  length  = 32
  special = false  # AUTH tokens don't support special chars
}
```

## What Was Simplified

From the original implementation, we removed:

- ❌ Cluster mode configuration (use standard replication)
- ❌ Custom parameter groups (use sensible defaults)
- ❌ CloudWatch alarms (add separately if needed)
- ❌ Logging configuration (use CloudWatch defaults)
- ❌ Multiple Parameter Store entries (one URL is enough)
- ❌ Optional security group creation (use existing)
- ❌ Conditional logic complexity

Result: **113 lines → 113 lines** with better clarity and zero config needed.

## Philosophy

This module follows the principle of **convention over configuration**:

1. **Sensible defaults** for 95% of use cases
2. **Single connection string** instead of individual parameters
3. **Production-ready** from the start
4. **Easy upgrade path** when needed
5. **Zero breaking changes** to Django code

## Next Steps

After deployment:

1. ✅ Test connection from ECS container
2. ✅ Configure Django cache/sessions
3. ✅ Set up Dramatiq workers
4. ✅ Monitor memory usage for first week
5. ✅ Upgrade to production settings when ready

## Support

For issues:
1. Check security groups
2. Verify VPC networking
3. Review CloudWatch metrics
4. Test from ECS container

## License

MIT - Use freely in your infrastructure.
