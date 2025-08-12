# CodePipeline Setup for Dev Environment

## Status: ✅ Successfully Deployed (December 2024)

## Overview

This document explains how to set up AWS CodePipeline for the Backend Booking dev environment. The pipeline automatically builds and deploys the Django application to ECS when changes are merged to the `dev` branch on GitHub.

**Current Status:**
- ✅ Pipeline deployed and operational
- ✅ GitHub connection established and working
- ✅ Automated builds triggering on push to `dev` branch
- ✅ Docker images successfully building and pushing to ECR
- ✅ ECS service updates working correctly

## Pipeline Architecture

```
GitHub (dev branch) → CodePipeline → CodeBuild → ECR → ECS Service
```

## Prerequisites

1. AWS account with appropriate permissions
2. GitHub repository (`seijihg/backend_booking`)
3. Terraform installed locally
4. Docker application code in the GitHub repository

## Setup Steps

### 1. Deploy the Infrastructure with CodePipeline

```bash
cd environments/dev

# Initialize Terraform (if not already done)
terraform init

# Plan the changes
terraform plan

# Apply the changes
terraform apply
```

### 2. Approve the CodeStar Connection

✅ **COMPLETED**: The CodeStar connection has been successfully established and is working.

1. Go to the AWS CodePipeline Console:
   ```
   https://eu-west-2.console.aws.amazon.com/codesuite/settings/connections
   ```

2. Find the connection named `backend-booking-dev-github`

3. The status will show as "Pending"

4. Click on the connection name and then click "Update pending connection"

5. You'll be redirected to GitHub to authorize the AWS Connector

6. Select your GitHub account/organization and the repository

7. Click "Connect" to complete the authorization

8. The connection status should change to "Available"

### 3. Verify the Pipeline

1. Check the AWS CodePipeline console:
   ```
   https://eu-west-2.console.aws.amazon.com/codesuite/codepipeline/pipelines
   ```

2. Look for the pipeline named `backend-booking-dev-pipeline`

3. The pipeline should have three stages:
   - **Source**: Pulls code from GitHub
   - **Build**: Builds Docker image and pushes to ECR
   - **Deploy**: Updates ECS service with new image

## Pipeline Triggers

The pipeline automatically triggers when:
- Code is pushed to the `dev` branch
- A pull request is merged into `dev`

## Build Process

The build process (defined in `modules/codepipeline/buildspec.yml`):
1. Logs into Amazon ECR
2. Builds the Docker image
3. Tags it with commit hash and `latest`
4. Runs security scan with Trivy
5. Pushes images to ECR
6. Creates `imagedefinitions.json` for ECS deployment

## Monitoring

### Build Logs
- CodeBuild logs are available in CloudWatch Logs
- Log group: `/aws/codebuild/backend-booking-dev-build`

### Pipeline Status
- View pipeline execution history in CodePipeline console
- Build badge URL available in Terraform output

### Notifications
- Configure SNS notifications by setting `enable_notifications = true`
- Add SNS topic ARN to receive pipeline status updates

## Troubleshooting

### Common Issues

1. **GitHub webhook not triggering**
   - Verify GitHub token has correct permissions
   - Check webhook is created in GitHub repository settings
   - Ensure branch name matches configuration

2. **Build failures**
   - Check CodeBuild logs in CloudWatch
   - Verify Dockerfile exists in repository root
   - Ensure all required environment variables are set

3. **Deployment failures**
   - Check ECS service events
   - Verify task definition is valid
   - Ensure health checks are passing

4. **Permission errors**
   - Verify CodePipeline and CodeBuild IAM roles have necessary permissions
   - Check Parameter Store access for secrets

## Cost Considerations

Estimated monthly costs for dev environment:
- CodePipeline: ~$1 (1 active pipeline)
- CodeBuild: ~$0.005 per build minute
- S3 (artifacts): ~$0.10
- Total: ~$2-5/month depending on build frequency

## Security Best Practices

1. **CodeStar Connection**: More secure than OAuth tokens, uses AWS-managed authentication
2. **No Token Storage**: No GitHub tokens stored in Parameter Store or code
3. **IAM Roles**: Use least-privilege principle for pipeline roles
4. **Container Scanning**: Trivy scan runs on each build
5. **Artifact Encryption**: S3 bucket uses AES256 encryption
6. **Build Environment**: Isolated CodeBuild environment for each build

## Customization

### Change Trigger Branch
Edit `environments/dev/main.tf`:
```hcl
github_branch = "dev"  # Currently set to "dev"
```

### Add Manual Approval
Set in the module configuration:
```hcl
require_manual_approval = true
```

### Increase Build Resources
Adjust compute type:
```hcl
build_compute_type = "BUILD_GENERAL1_MEDIUM"  # or LARGE
```

## Next Steps

1. **Production Pipeline**: Create separate pipeline for production with:
   - Manual approval stage
   - More comprehensive testing
   - Blue-green deployment strategy

2. **Enhanced Testing**: Add test stages:
   - Unit tests
   - Integration tests
   - Load testing

3. **Notifications**: Set up Slack/email notifications for pipeline events

## Related Documentation

- [AWS CodePipeline Documentation](https://docs.aws.amazon.com/codepipeline/)
- [CodeBuild Build Specification Reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)
- [ECS Blue/Green Deployments](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/deployment-type-bluegreen.html)