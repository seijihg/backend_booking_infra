# RDS PostgreSQL Module

This module creates an RDS PostgreSQL database instance with automatic Parameter Store integration for Django applications.

## Features

- **PostgreSQL Database** - Managed RDS instance with latest PostgreSQL 15
- **Security Groups** - Automatic security group creation with proper ingress rules
- **Parameter Store Integration** - Automatic update of database credentials
- **Backup Management** - Configurable backup retention and windows
- **Monitoring** - CloudWatch alarms for CPU, storage, and connections
- **Cost Optimization** - Options for single-AZ and minimal resources in dev
- **High Availability** - Multi-AZ support for production environments

## Architecture

```
Private Subnets (Multi-AZ)
         ↓
    RDS PostgreSQL
    ├── Primary Instance
    ├── Standby (if Multi-AZ)
    ├── Automated Backups
    └── Parameter Store
        ├── /database/host
        ├── /database/port
        ├── /database/name
        ├── /database/username
        └── /database/password
```

## Usage

### Basic Example (Development)

```hcl
module "rds" {
  source = "./modules/rds"

  app_name    = "backend-booking"
  environment = "dev"
  vpc_id      = module.networking.vpc_id
  
  # Requires at least 2 subnets in different AZs
  subnet_ids = module.networking.private_subnet_ids
  
  # Security groups that can access RDS
  security_group_ids = [aws_security_group.ecs_tasks.id]
  
  # Database configuration
  db_name     = "backend_booking_dev"
  db_username = "dbadmin"
  # Password auto-generated if not provided
  
  # Dev settings (cost-optimized)
  instance_class    = "db.t3.micro"  # Free tier
  allocated_storage = 20
  multi_az         = false
  
  # Minimal backups
  backup_retention_period = 1
  skip_final_snapshot    = true
  
  tags = {
    Environment = "dev"
  }
}
```

### Production Example

```hcl
module "rds" {
  source = "./modules/rds"

  app_name    = "backend-booking"
  environment = "prod"
  vpc_id      = module.networking.vpc_id
  
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [
    aws_security_group.ecs_tasks.id,
    aws_security_group.bastion.id  # For maintenance
  ]
  
  # Production configuration
  instance_class        = "db.t3.medium"
  allocated_storage     = 100
  max_allocated_storage = 500  # Auto-scaling
  storage_type          = "gp3"
  multi_az             = true  # High availability
  
  # Backup strategy
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  skip_final_snapshot    = false
  
  # Enhanced monitoring
  monitoring_interval          = 60
  performance_insights_enabled = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  # Security
  storage_encrypted    = true
  deletion_protection = true
  
  tags = {
    Environment = "prod"
    Critical    = "true"
  }
}
```

## Instance Sizing Guide

### Development/Testing
| Instance | vCPU | RAM | Network | Storage | Cost/Month |
|----------|------|-----|---------|---------|------------|
| db.t3.micro | 2 | 1 GB | Low | 20 GB | ~$15 |
| db.t3.small | 2 | 2 GB | Low | 20 GB | ~$30 |

### Production
| Instance | vCPU | RAM | Network | Storage | Cost/Month |
|----------|------|-----|---------|---------|------------|
| db.t3.medium | 2 | 4 GB | Moderate | 100 GB | ~$60 |
| db.m5.large | 2 | 8 GB | High | 100 GB | ~$120 |
| db.m5.xlarge | 4 | 16 GB | High | 200 GB | ~$240 |

## Parameter Store Integration

The module automatically updates Parameter Store with connection details:

```bash
# View stored parameters
aws ssm get-parameters-by-path \
  --path "/backend-booking/dev/database" \
  --recursive \
  --with-decryption
```

### Parameters Created
- `/backend-booking/{env}/database/host` - RDS endpoint
- `/backend-booking/{env}/database/port` - Database port (5432)
- `/backend-booking/{env}/database/name` - Database name
- `/backend-booking/{env}/database/username` - Master username
- `/backend-booking/{env}/database/password` - Master password (encrypted)

## Security Configuration

### Security Groups
The module creates a dedicated security group that:
- Only allows PostgreSQL port (5432) access
- Restricts access to specified security groups
- No public internet access

### Encryption
- **Storage Encryption**: Enabled by default using AWS KMS
- **In-Transit Encryption**: SSL/TLS connections supported
- **Parameter Store**: Passwords stored as SecureString

### IAM Database Authentication
Optional IAM authentication for enhanced security:
```hcl
iam_database_authentication_enabled = true
```

## Monitoring & Alarms

### CloudWatch Metrics
- CPU Utilization
- Database Connections
- Free Storage Space
- Read/Write IOPS
- Network Throughput

### Alarms (when monitoring enabled)
- High CPU (>80%)
- Low Storage (<2GB)
- High Connections (>50)

## Backup & Recovery

### Automated Backups
- Daily snapshots during backup window
- Point-in-time recovery within retention period
- Cross-region backup replication (optional)

### Manual Snapshots
```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier backend-booking-dev-db \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d)
```

### Restore from Snapshot
```bash
# Restore to new instance
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier restored-db \
  --db-snapshot-identifier snapshot-id
```

## Django Configuration

### Using Parameter Store Values
```python
# settings.py
import boto3
import json

ssm = boto3.client('ssm', region_name='eu-west-2')

def get_parameter(name):
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response['Parameter']['Value']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': get_parameter('/backend-booking/dev/database/name'),
        'USER': get_parameter('/backend-booking/dev/database/username'),
        'PASSWORD': get_parameter('/backend-booking/dev/database/password'),
        'HOST': get_parameter('/backend-booking/dev/database/host'),
        'PORT': get_parameter('/backend-booking/dev/database/port'),
    }
}
```

### Using Environment Variables (ECS)
```python
# settings.py (when using ECS task definition)
import os

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DATABASE_NAME'),
        'USER': os.environ.get('DATABASE_USER'),
        'PASSWORD': os.environ.get('DATABASE_PASSWORD'),
        'HOST': os.environ.get('DATABASE_HOST'),
        'PORT': os.environ.get('DATABASE_PORT', '5432'),
    }
}
```

## Maintenance

### Scaling
```bash
# Modify instance class
aws rds modify-db-instance \
  --db-instance-identifier backend-booking-dev-db \
  --db-instance-class db.t3.small \
  --apply-immediately
```

### Version Upgrades
```bash
# Upgrade PostgreSQL version
aws rds modify-db-instance \
  --db-instance-identifier backend-booking-dev-db \
  --engine-version 15.5 \
  --apply-immediately
```

## Cost Optimization

### Development
- Use `db.t3.micro` (free tier eligible)
- Single-AZ deployment
- Minimal backup retention (1 day)
- No enhanced monitoring

### Production
- Reserved instances for 1-3 year commitments (up to 70% savings)
- Use gp3 storage for better price/performance
- Enable storage auto-scaling to avoid over-provisioning
- Schedule dev/test instances to stop during off-hours

## Troubleshooting

### Connection Issues
1. Check security group rules
2. Verify ECS tasks are in allowed security groups
3. Ensure VPC endpoints or NAT Gateway configured
4. Check Parameter Store values are correct

### Performance Issues
1. Enable Performance Insights
2. Check slow query logs
3. Review connection pool settings
4. Consider scaling instance class

### High Costs
1. Review instance class sizing
2. Check backup retention settings
3. Disable unused monitoring features
4. Consider reserved instances

## Outputs

| Output | Description |
|--------|-------------|
| `db_instance_endpoint` | Full endpoint with port |
| `db_instance_address` | Hostname only |
| `db_instance_port` | Database port |
| `db_name` | Database name |
| `db_username` | Master username |
| `db_password` | Master password (sensitive) |
| `db_security_group_id` | Security group ID |
| `django_database_url` | Django-formatted connection string |
| `parameter_store_paths` | Map of Parameter Store paths |

## Migration from Existing Database

```bash
# Export from existing database
pg_dump -h old-host -U username -d dbname > backup.sql

# Import to RDS
psql -h $(terraform output -raw rds_endpoint) \
     -U $(aws ssm get-parameter --name /backend-booking/dev/database/username --query 'Parameter.Value' --output text) \
     -d $(aws ssm get-parameter --name /backend-booking/dev/database/name --query 'Parameter.Value' --output text) \
     < backup.sql
```