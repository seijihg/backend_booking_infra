# Makefile for Backend Booking Infrastructure
# Uses aws-vault with --no-session flag to avoid IAM/STS regional endpoint issues

AWS_PROFILE ?= le
ENV ?= dev

# Terraform commands with aws-vault
.PHONY: init plan apply destroy fmt validate

init:
	cd environments/$(ENV) && aws-vault exec $(AWS_PROFILE) --no-session -- terraform init

plan:
	cd environments/$(ENV) && aws-vault exec $(AWS_PROFILE) --no-session -- terraform plan

apply:
	cd environments/$(ENV) && aws-vault exec $(AWS_PROFILE) --no-session -- terraform apply

destroy:
	cd environments/$(ENV) && aws-vault exec $(AWS_PROFILE) --no-session -- terraform destroy

fmt:
	terraform fmt -recursive

validate:
	cd environments/$(ENV) && aws-vault exec $(AWS_PROFILE) --no-session -- terraform validate

# Output and state commands
.PHONY: output state-list refresh

output:
	cd environments/$(ENV) && aws-vault exec $(AWS_PROFILE) --no-session -- terraform output

state-list:
	cd environments/$(ENV) && aws-vault exec $(AWS_PROFILE) --no-session -- terraform state list

refresh:
	cd environments/$(ENV) && aws-vault exec $(AWS_PROFILE) --no-session -- terraform refresh

# Environment-specific shortcuts
.PHONY: dev-plan dev-apply prod-plan prod-apply

dev-plan:
	$(MAKE) plan ENV=dev

dev-apply:
	$(MAKE) apply ENV=dev

prod-plan:
	$(MAKE) plan ENV=prod

prod-apply:
	$(MAKE) apply ENV=prod

# AWS helper commands
.PHONY: aws-whoami ecs-tasks logs

aws-whoami:
	aws-vault exec $(AWS_PROFILE) --no-session -- aws sts get-caller-identity

ecs-tasks:
	aws-vault exec $(AWS_PROFILE) --no-session -- aws ecs list-tasks --cluster backend-booking-$(ENV)-cluster

logs:
	aws-vault exec $(AWS_PROFILE) --no-session -- aws logs tail /ecs/backend-booking-$(ENV) --follow

# Help
.PHONY: help
help:
	@echo "Backend Booking Infrastructure Makefile"
	@echo ""
	@echo "Usage: make <target> [ENV=dev|prod] [AWS_PROFILE=le]"
	@echo ""
	@echo "Terraform Commands:"
	@echo "  init        - Initialize Terraform"
	@echo "  plan        - Show execution plan"
	@echo "  apply       - Apply changes"
	@echo "  destroy     - Destroy infrastructure"
	@echo "  fmt         - Format Terraform files"
	@echo "  validate    - Validate configuration"
	@echo "  output      - Show outputs"
	@echo "  state-list  - List state resources"
	@echo "  refresh     - Refresh state"
	@echo ""
	@echo "Shortcuts:"
	@echo "  dev-plan    - Plan for dev environment"
	@echo "  dev-apply   - Apply to dev environment"
	@echo "  prod-plan   - Plan for prod environment"
	@echo "  prod-apply  - Apply to prod environment"
	@echo ""
	@echo "AWS Helpers:"
	@echo "  aws-whoami  - Show current AWS identity"
	@echo "  ecs-tasks   - List ECS tasks"
	@echo "  logs        - Tail ECS logs"
	@echo ""
	@echo "Examples:"
	@echo "  make plan                    # Plan dev (default)"
	@echo "  make apply ENV=prod          # Apply to prod"
	@echo "  make plan AWS_PROFILE=other  # Use different profile"
