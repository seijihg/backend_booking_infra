# ECS Service Module Variables

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Service Configuration
variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = ""
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the task definition"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "launch_type" {
  description = "Launch type for the service (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
}

variable "platform_version" {
  description = "Platform version for Fargate"
  type        = string
  default     = "LATEST"
}

# Network Configuration
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the service"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the service"
  type        = bool
  default     = false
}

# Load Balancer Configuration
variable "enable_load_balancer" {
  description = "Whether to attach the service to a load balancer"
  type        = bool
  default     = true
}

variable "target_group_arn" {
  description = "ARN of the target group"
  type        = string
  default     = ""
}

variable "container_name" {
  description = "Name of the container to associate with the load balancer"
  type        = string
}

variable "container_port" {
  description = "Port of the container"
  type        = number
  default     = 8000
}

# Auto Scaling Configuration
variable "enable_autoscaling" {
  description = "Enable auto-scaling for the service"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 4
}

variable "scale_up_cooldown" {
  description = "Cooldown period for scale up (seconds)"
  type        = number
  default     = 60
}

variable "scale_down_cooldown" {
  description = "Cooldown period for scale down (seconds)"
  type        = number
  default     = 300
}

# CPU Auto-scaling
variable "cpu_scale_up_threshold" {
  description = "CPU utilization threshold for scaling up"
  type        = number
  default     = 70
}

variable "cpu_scale_down_threshold" {
  description = "CPU utilization threshold for scaling down"
  type        = number
  default     = 30
}

# Memory Auto-scaling
variable "memory_scale_up_threshold" {
  description = "Memory utilization threshold for scaling up"
  type        = number
  default     = 70
}

variable "memory_scale_down_threshold" {
  description = "Memory utilization threshold for scaling down"
  type        = number
  default     = 30
}

# Request Count Auto-scaling (ALB)
variable "enable_request_count_scaling" {
  description = "Enable scaling based on ALB request count"
  type        = bool
  default     = false
}

variable "target_requests_per_task" {
  description = "Target number of requests per task for scaling"
  type        = number
  default     = 1000
}

# Deployment Configuration
variable "deployment_maximum_percent" {
  description = "Maximum percent of tasks during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployment"
  type        = number
  default     = 100
}

variable "health_check_grace_period_seconds" {
  description = "Grace period for health checks (seconds)"
  type        = number
  default     = 60
}

variable "force_new_deployment" {
  description = "Force a new deployment of the service"
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Wait for the service to reach steady state"
  type        = bool
  default     = false
}

# Circuit Breaker
variable "enable_deployment_circuit_breaker" {
  description = "Enable deployment circuit breaker"
  type        = bool
  default     = true
}

variable "enable_deployment_rollback" {
  description = "Enable automatic rollback on deployment failure"
  type        = bool
  default     = true
}

# Service Discovery
variable "enable_service_discovery" {
  description = "Enable service discovery"
  type        = bool
  default     = false
}

variable "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  type        = string
  default     = ""
}

# Capacity Provider Strategy
variable "use_capacity_provider_strategy" {
  description = "Use capacity provider strategy instead of launch type"
  type        = bool
  default     = false
}

variable "capacity_provider_strategies" {
  description = "Capacity provider strategies"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  default = []
}

# Placement Constraints
variable "placement_constraints" {
  description = "Placement constraints for the service"
  type = list(object({
    type       = string
    expression = string
  }))
  default = []
}

# Placement Strategy
variable "ordered_placement_strategies" {
  description = "Placement strategies for the service"
  type = list(object({
    type  = string
    field = string
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to the service"
  type        = map(string)
  default     = {}
}

# Service Registries
variable "service_registries" {
  description = "Service registries for the service"
  type = list(object({
    registry_arn   = string
    port          = optional(number)
    container_port = optional(number)
    container_name = optional(string)
  }))
  default = []
}

# Propagate Tags
variable "propagate_tags" {
  description = "Propagate tags from service or task definition to tasks"
  type        = string
  default     = "SERVICE"
  validation {
    condition     = contains(["SERVICE", "TASK_DEFINITION", "NONE"], var.propagate_tags)
    error_message = "propagate_tags must be SERVICE, TASK_DEFINITION, or NONE."
  }
}

# Enable Execute Command (ECS Exec)
variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging"
  type        = bool
  default     = false
}