# ECS Container Access & Health Check Testing Guide

## Quick Start

### Method 1: ECS Exec (Recommended for Fargate)

```bash
# Run the automated script
cd environments/dev
./ecs-container-access.sh

# Or manually access the container
aws ecs execute-command \
    --cluster backend-booking-dev-cluster \
    --task <task-id> \
    --container backend-booking \
    --interactive \
    --command "/bin/bash" \
    --region eu-west-2
```

### Method 2: Direct Health Check Testing

Without logging into the container, test from outside:

```bash
# Get the ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names backend-booking-dev-alb \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

# Test health endpoint
curl http://$ALB_DNS/health/
```

## Enabling ECS Exec (First Time Setup)

ECS Exec must be enabled on the service before you can access containers:

```bash
# Enable ECS Exec
aws ecs update-service \
    --cluster backend-booking-dev-cluster \
    --service backend-booking-dev-app \
    --enable-execute-command \
    --force-new-deployment

# Wait for new tasks to start (2-3 minutes)
aws ecs wait services-stable \
    --cluster backend-booking-dev-cluster \
    --services backend-booking-dev-app
```

## Testing Health Checks Inside Container

Once you're inside the container, test various health checks:

### 1. Test Django Health Endpoint
```bash
# Using curl
curl -f http://localhost:8000/health/

# Using wget (if curl not available)
wget -O- http://localhost:8000/health/

# Using Python
python -c "
import urllib.request
response = urllib.request.urlopen('http://localhost:8000/health/')
print('Status:', response.status)
print(response.read().decode())
"
```

### 2. Test Database Connection
```bash
# Using Django shell
python manage.py shell -c "
from django.db import connection
with connection.cursor() as cursor:
    cursor.execute('SELECT 1')
    print('Database is connected')
"

# Check if using PgBouncer
nc -zv localhost 6432  # PgBouncer port
nc -zv $DATABASE_HOST 5432  # Direct PostgreSQL
```

### 3. Test Redis Connection
```bash
# Using Django shell
python manage.py shell -c "
from django.core.cache import cache
cache.set('test', 'value', 1)
print('Redis test:', cache.get('test'))
"

# Using redis-cli (if installed)
redis-cli -h $REDIS_HOST ping
```

### 4. Check Running Processes
```bash
# See what's running
ps aux | grep python
ps aux | grep gunicorn

# Check if Django is responding
curl -I http://localhost:8000/
```

### 5. Check Environment Variables
```bash
# View all environment variables
env | grep -E "DJANGO|DATABASE|REDIS|AWS"

# Check specific ones
echo "DATABASE_URL: $DATABASE_URL"
echo "REDIS_URL: $REDIS_URL"
echo "ALLOWED_HOSTS: $ALLOWED_HOSTS"
```

### 6. Check Listening Ports
```bash
# See what ports are open
netstat -tuln | grep LISTEN
# or
ss -tuln | grep LISTEN

# Should see:
# 8000 - Django application
# 6432 - PgBouncer (if using)
```

## Common Health Check Issues

### Issue: Connection Refused on Port 8000
```bash
# Check if Django is running
ps aux | grep python

# Check Django logs
tail -f /var/log/django.log  # If configured
# or check stdout/stderr
```

### Issue: Database Connection Failed
```bash
# Test PgBouncer
psql -h localhost -p 6432 -U $DATABASE_USER -d $DATABASE_NAME -c "SELECT 1"

# Test direct database
psql -h $DATABASE_HOST -p 5432 -U $DATABASE_USER -d $DATABASE_NAME -c "SELECT 1"

# Check credentials
echo $DATABASE_URL | sed 's/:[^:]*@/:***@/'  # Hide password
```

### Issue: Health Check Timeout
```bash
# Time the health check
time curl http://localhost:8000/health/

# If slow, check what the health endpoint does
grep -r "def health" --include="*.py"
```

## ALB Health Check Configuration

The ALB health check settings that affect your container:

```bash
# View current health check configuration
aws elbv2 describe-target-groups \
    --names backend-booking-dev-tg \
    --query 'TargetGroups[0].HealthCheckPath'

# Common settings to check:
# - HealthCheckPath: /health/
# - HealthCheckIntervalSeconds: 30
# - HealthCheckTimeoutSeconds: 5
# - HealthyThresholdCount: 2
# - UnhealthyThresholdCount: 3
```

## Debugging Failed Health Checks

### 1. Check Container Logs
```bash
# From outside the container
aws logs tail /ecs/backend-booking-dev --follow --since 5m

# Filter for errors
aws logs filter-log-events \
    --log-group-name /ecs/backend-booking-dev \
    --filter-pattern "ERROR"
```

### 2. Test from Load Balancer Perspective
```bash
# Get task IP
TASK_IP=$(aws ecs describe-tasks \
    --cluster backend-booking-dev-cluster \
    --tasks <task-arn> \
    --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' \
    --output text)

# Test from same VPC (if you have a bastion host)
ssh bastion-host
curl http://$TASK_IP:8000/health/
```

### 3. Common Fixes

#### Increase Health Check Grace Period
```bash
aws ecs update-service \
    --cluster backend-booking-dev-cluster \
    --service backend-booking-dev-app \
    --health-check-grace-period-seconds 120
```

#### Simplify Health Check Endpoint
```python
# In Django urls.py
def simple_health(request):
    # Don't check database/redis on every health check
    return JsonResponse({'status': 'ok'})

urlpatterns = [
    path('health/', simple_health),  # Fast health check for ALB
    path('health/full/', full_health_check),  # Detailed check for monitoring
]
```

## Useful Debugging Commands Inside Container

```bash
# Check Django configuration
python manage.py check
python manage.py check --deploy

# Test database migrations
python manage.py showmigrations

# Check static files
python manage.py collectstatic --noinput --dry-run

# Run Django shell
python manage.py shell

# Check installed packages
pip list

# Check disk space
df -h

# Check memory
free -m

# Network debugging
ping -c 1 google.com  # Internet connectivity
nslookup $DATABASE_HOST  # DNS resolution
traceroute $DATABASE_HOST  # Network path
```

## Security Note

ECS Exec sessions are logged in CloudTrail and Session Manager. Always:
- Use read-only commands when possible
- Avoid running commands that modify data
- Don't expose sensitive information in commands
- Close sessions when done

## Automation Script

The provided `ecs-container-access.sh` script automates:
1. Checking if ECS Exec is enabled
2. Enabling it if needed (requires service restart)
3. Finding running tasks
4. Providing ready-to-use commands
5. Optionally opening an interactive shell

Run it with:
```bash
./ecs-container-access.sh [cluster-name] [service-name]
```

Default values match your setup:
- Cluster: `backend-booking-dev-cluster`
- Service: `backend-booking-dev-app`