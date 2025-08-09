# ECS Service Module

locals {
  service_name = var.service_name != "" ? var.service_name : "${var.app_name}-${var.environment}"
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                               = local.service_name
  cluster                            = var.cluster_id
  task_definition                    = var.task_definition_arn
  desired_count                      = var.desired_count
  launch_type                        = var.use_capacity_provider_strategy ? null : var.launch_type
  platform_version                   = var.launch_type == "FARGATE" ? var.platform_version : null
  health_check_grace_period_seconds = var.enable_load_balancer ? var.health_check_grace_period_seconds : null
  force_new_deployment              = var.force_new_deployment
  wait_for_steady_state            = var.wait_for_steady_state
  enable_execute_command           = var.enable_execute_command
  propagate_tags                   = var.propagate_tags
  
  # Deployment Configuration (as direct attributes)
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent

  # Network Configuration (required for Fargate)
  network_configuration {
    security_groups  = var.security_group_ids
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
  }

  # Load Balancer Configuration
  dynamic "load_balancer" {
    for_each = var.enable_load_balancer && var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }

  # Deployment Circuit Breaker
  deployment_circuit_breaker {
    enable   = var.enable_deployment_circuit_breaker
    rollback = var.enable_deployment_rollback
  }

  # Capacity Provider Strategy
  dynamic "capacity_provider_strategy" {
    for_each = var.use_capacity_provider_strategy ? var.capacity_provider_strategies : []
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  # Placement Constraints
  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  # Placement Strategy
  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategies
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  # Service Registries (for Service Discovery)
  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = lookup(service_registries.value, "port", null)
      container_port = lookup(service_registries.value, "container_port", null)
      container_name = lookup(service_registries.value, "container_name", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = local.service_name
      Environment = var.environment
      Application = var.app_name
      ManagedBy   = "Terraform"
    }
  )

  lifecycle {
    ignore_changes = [desired_count] # Allow autoscaling to manage this
  }

  depends_on = [
    var.target_group_arn # Ensure target group exists before creating service
  ]
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs" {
  count = var.enable_autoscaling ? 1 : 0

  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_id}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity

  depends_on = [aws_ecs_service.main]
}

# Auto Scaling Policy - CPU Utilization
resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.service_name}-cpu-scaling"
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_scale_up_threshold
    scale_in_cooldown  = var.scale_down_cooldown
    scale_out_cooldown = var.scale_up_cooldown
  }
}

# Auto Scaling Policy - Memory Utilization
resource "aws_appautoscaling_policy" "memory" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.service_name}-memory-scaling"
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_scale_up_threshold
    scale_in_cooldown  = var.scale_down_cooldown
    scale_out_cooldown = var.scale_up_cooldown
  }
}

# Auto Scaling Policy - ALB Request Count (Optional)
resource "aws_appautoscaling_policy" "alb_requests" {
  count = var.enable_autoscaling && var.enable_request_count_scaling && var.enable_load_balancer ? 1 : 0

  name               = "${local.service_name}-alb-requests-scaling"
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = join("/", [
        split(":", var.target_group_arn)[5],
        split(":", var.target_group_arn)[6]
      ])
    }
    target_value       = var.target_requests_per_task
    scale_in_cooldown  = var.scale_down_cooldown
    scale_out_cooldown = var.scale_up_cooldown
  }
}

# CloudWatch Dashboard (Optional)
resource "aws_cloudwatch_dashboard" "service" {
  count = var.enable_autoscaling ? 1 : 0

  dashboard_name = "${local.service_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.main.name, "ClusterName", var.cluster_id],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ECS Service Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "DesiredTaskCount", "ServiceName", aws_ecs_service.main.name, "ClusterName", var.cluster_id],
            [".", "RunningTaskCount", ".", ".", ".", "."],
            [".", "PendingTaskCount", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Task Count"
        }
      }
    ]
  })
}

# Data source for current region
data "aws_region" "current" {}