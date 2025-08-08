#!/bin/bash

# Script to setup GitHub token in AWS Parameter Store for CodePipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PARAMETER_NAME="/backend-booking/common/github-token"
AWS_REGION=${AWS_REGION:-"eu-west-2"}

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_message "$RED" "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated with AWS
if ! aws sts get-caller-identity &> /dev/null; then
    print_message "$RED" "Error: Not authenticated with AWS. Please configure AWS credentials."
    exit 1
fi

print_message "$GREEN" "=== GitHub Token Setup for CodePipeline ==="
echo ""

# Ask for environment
read -p "Enter environment (dev/prod/common) [common]: " ENV
ENV=${ENV:-common}

if [ "$ENV" != "common" ]; then
    PARAMETER_NAME="/backend-booking/$ENV/github-token"
fi

# Check if parameter already exists
if aws ssm get-parameter --name "$PARAMETER_NAME" --region "$AWS_REGION" &> /dev/null; then
    print_message "$YELLOW" "Warning: Parameter $PARAMETER_NAME already exists."
    read -p "Do you want to update it? (y/n): " UPDATE
    if [ "$UPDATE" != "y" ]; then
        print_message "$YELLOW" "Skipping..."
        exit 0
    fi
fi

# Instructions for creating GitHub token
print_message "$YELLOW" "\nTo create a GitHub personal access token:"
echo "1. Go to https://github.com/settings/tokens"
echo "2. Click 'Generate new token' → 'Generate new token (classic)'"
echo "3. Give it a descriptive name (e.g., 'CodePipeline - Backend Booking')"
echo "4. Select the following scopes:"
echo "   ✓ repo (Full control of private repositories)"
echo "   ✓ admin:repo_hook (Full control of repository hooks)"
echo "5. Click 'Generate token' and copy it"
echo ""

# Ask for GitHub token
read -s -p "Enter your GitHub personal access token (ghp_...): " GITHUB_TOKEN
echo ""

# Validate token format
if [[ ! $GITHUB_TOKEN =~ ^ghp_[a-zA-Z0-9]{36}$ ]]; then
    print_message "$RED" "Error: Invalid token format. GitHub tokens start with 'ghp_' followed by 36 characters."
    exit 1
fi

# Store in Parameter Store
print_message "$YELLOW" "\nStoring token in Parameter Store..."

if aws ssm put-parameter \
    --name "$PARAMETER_NAME" \
    --value "$GITHUB_TOKEN" \
    --type "SecureString" \
    --description "GitHub personal access token for CodePipeline" \
    --overwrite \
    --region "$AWS_REGION" > /dev/null 2>&1; then
    
    print_message "$GREEN" "✓ Token stored successfully at: $PARAMETER_NAME"
    
    # Verify storage
    if aws ssm get-parameter --name "$PARAMETER_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
        print_message "$GREEN" "✓ Token verified successfully"
    fi
    
    echo ""
    print_message "$GREEN" "You can now use this in your Terraform configuration:"
    echo ""
    echo "module \"codepipeline\" {"
    echo "  source = \"./modules/codepipeline\""
    echo "  ..."
    echo "  github_token_parameter_name = \"$PARAMETER_NAME\""
    echo "  ..."
    echo "}"
    
else
    print_message "$RED" "Error: Failed to store token in Parameter Store"
    exit 1
fi

echo ""
print_message "$GREEN" "Setup complete! 🎉"