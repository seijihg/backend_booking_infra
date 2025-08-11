# PgBouncer Troubleshooting Guide

## The Problem

When DATABASE_URL and individual database parameters (host, username, password, etc.) don't match, PgBouncer fails to connect because:

- Django uses DATABASE_URL
- PgBouncer uses individual parameters (it doesn't understand DATABASE_URL format)
- If they don't match, PgBouncer connects to the wrong database or with wrong credentials

## Quick Diagnosis

### 1. Check Parameter Consistency

```bash
./check-pgbouncer.sh
```

This will:

- Compare DATABASE_URL with individual parameters
- Check ECS service status
- Verify PgBouncer container health
- Show recent PgBouncer logs

### 2. Fix Parameter Mismatches

If parameters don't match:

```bash
./sync-database-params.sh
```

This will:

- Parse DATABASE_URL
- Update individual parameters to match
- Optionally restart ECS tasks

### 3. Monitor PgBouncer Health

```bash
./monitor-pgbouncer.sh dev 5  # Refresh every 5 seconds
```

Real-time monitoring of:

- Container status
- Error logs
- Connection activity
- Django database errors

## How PgBouncer Works in Your Setup

```
Django App (Container 1)
    ↓
    Connects to localhost:6432
    ↓
PgBouncer (Container 2 - Sidecar)
    ↓
    Connection pooling (25 connections)
    ↓
RDS PostgreSQL
```

### Configuration

- **PgBouncer Port**: 6432 (internal to task)
- **Pool Mode**: Transaction (releases connection after each transaction)
- **Max Client Connections**: 1000 (from Django)
- **Default Pool Size**: 25 (to RDS)

## Common Issues and Solutions

### Issue 1: Connection Refused

**Symptom**: Django can't connect to database
**Check**:

```bash
# Check if parameters match
./check-pgbouncer.sh

# Look for this error in logs
aws logs filter-log-events --log-group-name /ecs/backend-booking-dev \
    --filter-pattern "connection refused"
```

**Fix**: Run `./sync-database-params.sh`

### Issue 2: Authentication Failed

**Symptom**: PgBouncer logs show "authentication failed"
**Check**:

```bash
# Verify password matches
aws ssm get-parameter --name /backend-booking/dev/database/password --with-decryption
# Compare with password in DATABASE_URL
aws ssm get-parameter --name /backend-booking/dev/database/url --with-decryption
```

**Fix**: Synchronize parameters or update DATABASE_URL

### Issue 3: PgBouncer Not Running

**Symptom**: Container keeps restarting
**Check**:

```bash
# Check container status
aws ecs describe-tasks --cluster backend-booking-dev \
    --tasks $(aws ecs list-tasks --cluster backend-booking-dev --query 'taskArns[0]' --output text) \
    --query 'tasks[0].containers[?name==`pgbouncer`]'
```

**Fix**: Check PgBouncer configuration in task definition

### Issue 4: Too Many Connections

**Symptom**: "too many connections" error
**Check**:

```bash
# Monitor connection patterns
./monitor-pgbouncer.sh dev 2
```

**Fix**: Increase pool size or optimize Django connection usage

## Manual Testing

### Test from ECS Task (using ECS Exec)

```bash
# Enable ECS Exec
aws ecs update-service --cluster backend-booking-dev \
    --service backend-booking-dev-service \
    --enable-execute-command

# Connect to task
aws ecs execute-command --cluster backend-booking-dev \
    --task <task-id> \
    --container backend-booking \
    --interactive \
    --command "/bin/bash"

# Inside container, test connections:
# Test PgBouncer
psql -h localhost -p 6432 -U backend_booking_dev -d backend_booking_dev

# Test direct database (bypass PgBouncer)
psql -h <rds-endpoint> -p 5432 -U backend_booking_dev -d backend_booking_dev
```

### Test from Local Machine

```bash
# Port forward to PgBouncer (requires Session Manager)
aws ssm start-session --target <ecs-instance-id> \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["6432"],"localPortNumber":["6432"]}'

# Connect locally
psql -h localhost -p 6432 -U backend_booking_dev -d backend_booking_dev
```

## Best Practices

1. **Always Keep Parameters Synchronized**

   - When updating DATABASE_URL, also update individual parameters
   - Use the sync script after any database changes

2. **Monitor After Deployments**

   - Run `./monitor-pgbouncer.sh` after deployments
   - Check for authentication errors or connection issues

3. **Use Transaction Pooling Mode**

   - Best for Django's short-lived queries
   - Releases connections after each transaction

4. **Set Appropriate Pool Size**
   - Default: 25 connections to RDS
   - Adjust based on your RDS instance size
   - Monitor usage with CloudWatch metrics

## Terraform Configuration

To prevent future mismatches, ensure your Terraform uses consistent values:

```hcl
# parameters.tf
locals {
  db_username = "backend_booking_${var.environment}"
  db_password = var.database_password != "" ? var.database_password : "dev-password-change-in-production"
  db_host     = var.database_host != "" ? var.database_host : "placeholder"
  db_name     = var.database_name
}

resource "aws_ssm_parameter" "database_url" {
  value = "postgresql://${local.db_username}:${local.db_password}@${local.db_host}:5432/${local.db_name}"
}

resource "aws_ssm_parameter" "database_host" {
  value = local.db_host
}

resource "aws_ssm_parameter" "database_username" {
  value = local.db_username
}

resource "aws_ssm_parameter" "database_password" {
  value = local.db_password
}
```

## Emergency Recovery

If everything is broken:

1. **Stop ECS Service**:

```bash
aws ecs update-service --cluster backend-booking-dev \
    --service backend-booking-dev-service \
    --desired-count 0
```

2. **Fix Parameters**:

```bash
./sync-database-params.sh
```

3. **Restart Service**:

```bash
aws ecs update-service --cluster backend-booking-dev \
    --service backend-booking-dev-service \
    --desired-count 2 \
    --force-new-deployment
```

4. **Monitor Recovery**:

```bash
./monitor-pgbouncer.sh dev 2
```
