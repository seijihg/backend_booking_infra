# CodePipeline Module

This module creates a complete CI/CD pipeline for building Docker images from GitHub and deploying them to ECS using AWS CodePipeline.

## Architecture

```
GitHub Repository
    ↓ (Webhook on push)
CodePipeline
    ├── Source Stage
    │   └── GitHub Source (main branch)
    ├── Build Stage
    │   └── CodeBuild Project
    │       ├── Pull source code
    │       ├── Build Docker image
    │       ├── Run tests (optional)
    │       ├── Security scan (Trivy)
    │       └── Push to ECR
    └── Deploy Stage
        ├── Manual Approval (optional)
        └── ECS Deployment
            └── Update service with new image
```

## Pipeline Flow

1. **Source Stage**: Triggered by push to GitHub main branch
2. **Build Stage**: Builds Docker image and pushes to ECR
3. **Deploy Stage**: Updates ECS service with new container image

## Usage

### Basic Example

```hcl
module "codepipeline" {
  source = "./modules/codepipeline"

  app_name    = "backend-booking"
  environment = "dev"

  # GitHub Configuration
  github_owner  = "seijihg"
  github_repo   = "backend_booking"
  github_branch = "main"
  github_token_parameter_name = "/backend-booking/common/github-token"  # Default path

  # ECR Configuration
  ecr_repository_url = aws_ecr_repository.app.repository_url

  # ECS Configuration
  ecs_cluster_name             = module.ecs_cluster.cluster_name
  ecs_service_name             = "backend-booking-dev-service"  # When service exists
  ecs_task_execution_role_arn  = module.ecs_cluster.task_execution_role_arn
  ecs_task_role_arn            = module.ecs_cluster.task_role_arn

  tags = {
    Environment = "dev"
    Project     = "Backend Booking"
  }
}
```

### Production Example with Approval

```hcl
module "codepipeline" {
  source = "./modules/codepipeline"

  app_name    = "backend-booking"
  environment = "prod"

  # GitHub Configuration
  github_owner  = "seijihg"
  github_repo   = "backend_booking"
  github_branch = "main"
  github_token_parameter_name = "/backend-booking/prod/github-token"  # Environment-specific

  # ECR Configuration
  ecr_repository_url = aws_ecr_repository.app.repository_url

  # ECS Configuration
  ecs_cluster_name             = module.ecs_cluster.cluster_name
  ecs_service_name             = "backend-booking-prod-service"
  ecs_task_execution_role_arn  = module.ecs_cluster.task_execution_role_arn
  ecs_task_role_arn            = module.ecs_cluster.task_role_arn

  # Production settings
  require_manual_approval = true
  build_compute_type      = "BUILD_GENERAL1_MEDIUM"
  build_timeout          = 60
  deployment_timeout     = 20

  # Notifications
  enable_notifications = true
  sns_topic_arn       = aws_sns_topic.alerts.arn

  # VPC Configuration (for private resources during build)
  enable_vpc_config  = true
  vpc_id            = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  # Build secrets from Parameter Store
  build_parameter_store_secrets = {
    "DJANGO_SECRET_KEY" = "/backend-booking/prod/app/django-secret-key"
  }

  tags = {
    Environment = "prod"
    Project     = "Backend Booking"
  }
}
```

## Prerequisites

### 1. GitHub Personal Access Token

Create a GitHub personal access token with the following permissions:
- `repo` - Full control of private repositories
- `admin:repo_hook` - Full control of repository hooks

Store the token securely in Parameter Store:
```bash
# Store in Parameter Store as SecureString (recommended)
aws ssm put-parameter \
  --name "/backend-booking/common/github-token" \
  --value "ghp_xxxxxxxxxxxxxxxxxxxx" \
  --type "SecureString" \
  --description "GitHub personal access token for CodePipeline"

# For environment-specific tokens
aws ssm put-parameter \
  --name "/backend-booking/dev/github-token" \
  --value "ghp_xxxxxxxxxxxxxxxxxxxx" \
  --type "SecureString" \
  --description "GitHub token for dev pipeline"
```

### 2. ECR Repository

The ECR repository must exist before creating the pipeline:
```hcl
resource "aws_ecr_repository" "app" {
  name = "backend-booking"
}
```

### 3. ECS Cluster

The ECS cluster must exist (service is optional initially):
```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"
  # ... configuration ...
}
```

## Build Process

The build process is defined in `buildspec.yml`:

1. **Pre-build**: Login to ECR
2. **Build**: 
   - Build Docker image
   - Tag with commit hash and "latest"
   - Run security scan (Trivy)
3. **Post-build**:
   - Push images to ECR
   - Create `imagedefinitions.json` for ECS deployment
   - Update Parameter Store with deployment metadata

## Customizing the Build

### Modify buildspec.yml

You can override the default buildspec by providing your own:

```hcl
# In your CodeBuild project
source {
  type      = "CODEPIPELINE"
  buildspec = file("${path.root}/custom-buildspec.yml")
}
```

### Add Test Stage

Add tests to the build phase:
```yaml
build:
  commands:
    - docker build -t $REPOSITORY_URI:latest .
    - docker run --rm $REPOSITORY_URI:latest python manage.py test
    - docker run --rm $REPOSITORY_URI:latest python manage.py check --deploy
```

### Multi-Stage Builds

For production, use multi-stage Docker builds:
```dockerfile
# Build stage
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Production stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
```

## Deployment Strategies

### Rolling Update (Default)

ECS performs a rolling update, replacing tasks one by one:
```hcl
deployment_maximum_percent = 200
deployment_minimum_healthy_percent = 100
```

### Blue/Green Deployment

For zero-downtime deployments (requires additional configuration):
```hcl
deployment_controller {
  type = "CODE_DEPLOY"
}
```

## Monitoring

### Pipeline Metrics

- Pipeline execution success/failure rate
- Build duration
- Deployment success rate
- Time to deploy

### CloudWatch Alarms

The module creates alarms for:
- Pipeline failures
- Build failures
- Long build duration
- Deployment failures

### Notifications

Enable notifications to receive alerts:
```hcl
enable_notifications = true
sns_topic_arn = aws_sns_topic.alerts.arn
```

## Cost Optimization

### Development Environment

- Use `BUILD_GENERAL1_SMALL` for builds
- Disable manual approval
- Shorter log retention (7 days)

### Production Environment

- Use `BUILD_GENERAL1_MEDIUM` or larger for faster builds
- Enable build caching
- Consider reserved capacity for frequent builds

### Estimated Costs

- CodePipeline: $1/month per active pipeline
- CodeBuild: $0.005/minute (Linux small)
- S3 Storage: ~$0.023/GB for artifacts
- Total: ~$5-20/month depending on build frequency

## Security Considerations

1. **GitHub Token**: Stored in Parameter Store as SecureString (encrypted with KMS)
2. **IAM Roles**: Least privilege principle applied
3. **Container Scanning**: Trivy scans for vulnerabilities
4. **Parameter Store**: Sensitive data encrypted with KMS
5. **VPC Endpoints**: Use VPC endpoints for AWS services

## Troubleshooting

### Common Issues

1. **GitHub webhook not triggering**
   - Verify GitHub token has correct permissions
   - Check webhook is created in GitHub repository

2. **Build fails with "Cannot connect to Docker daemon"**
   - Ensure `privileged_mode = true` in CodeBuild

3. **ECR push fails**
   - Verify CodeBuild role has ECR permissions
   - Check ECR repository exists

4. **ECS deployment fails**
   - Ensure ECS service exists (or remove deploy stage initially)
   - Verify task definition is valid
   - Check health checks are passing

### Viewing Logs

```bash
# View pipeline execution
aws codepipeline get-pipeline-execution \
  --pipeline-name backend-booking-dev-pipeline \
  --pipeline-execution-id <execution-id>

# View build logs
aws codebuild batch-get-builds \
  --ids <build-id>

# CloudWatch logs
aws logs tail /aws/codebuild/backend-booking-dev --follow
```

## Future Enhancements

1. **Multi-environment pipelines**: Deploy to dev → staging → prod
2. **Automated testing**: Integration and E2E tests
3. **Canary deployments**: Gradual traffic shifting
4. **Rollback automation**: Automatic rollback on metric alarms
5. **Cross-region deployment**: Multi-region support