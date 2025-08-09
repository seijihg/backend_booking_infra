# ECS Service Module Outputs

output "service_id" {
  description = "ARN that identifies the service"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "Name of the service"
  value       = aws_ecs_service.main.name
}

output "service_cluster" {
  description = "Amazon Resource Name (ARN) of cluster which the service runs on"
  value       = aws_ecs_service.main.cluster
}

output "service_iam_role" {
  description = "ARN of IAM role used for ELB"
  value       = try(aws_ecs_service.main.iam_role, null)
}

output "service_desired_count" {
  description = "Number of instances of the task definition"
  value       = aws_ecs_service.main.desired_count
}

# Auto-scaling Outputs
output "autoscaling_target_id" {
  description = "ID of the auto-scaling target"
  value       = try(aws_appautoscaling_target.ecs[0].id, null)
}

output "autoscaling_target_min_capacity" {
  description = "Minimum capacity of the auto-scaling target"
  value       = try(aws_appautoscaling_target.ecs[0].min_capacity, null)
}

output "autoscaling_target_max_capacity" {
  description = "Maximum capacity of the auto-scaling target"
  value       = try(aws_appautoscaling_target.ecs[0].max_capacity, null)
}

output "cpu_scaling_policy_arn" {
  description = "ARN of the CPU auto-scaling policy"
  value       = try(aws_appautoscaling_policy.cpu[0].arn, null)
}

output "memory_scaling_policy_arn" {
  description = "ARN of the memory auto-scaling policy"
  value       = try(aws_appautoscaling_policy.memory[0].arn, null)
}

output "alb_requests_scaling_policy_arn" {
  description = "ARN of the ALB requests auto-scaling policy"
  value       = try(aws_appautoscaling_policy.alb_requests[0].arn, null)
}

# Dashboard Output
output "cloudwatch_dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = try(aws_cloudwatch_dashboard.service[0].dashboard_arn, null)
}

# Service Discovery
output "service_registries" {
  description = "Service discovery registries for the service"
  value       = aws_ecs_service.main.service_registries
}