# Outputs for ECS Worker Module

output "worker_service_name" {
  description = "Name of the ECS worker service"
  value       = aws_ecs_service.worker.name
}

output "worker_service_id" {
  description = "ID of the ECS worker service"
  value       = aws_ecs_service.worker.id
}

output "worker_task_definition_arn" {
  description = "ARN of the worker task definition"
  value       = aws_ecs_task_definition.worker.arn
}

output "worker_task_definition_family" {
  description = "Family of the worker task definition"
  value       = aws_ecs_task_definition.worker.family
}

output "worker_task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.worker_execution_role.arn
}

output "worker_task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.worker_task_role.arn
}

output "worker_log_group_name" {
  description = "Name of the CloudWatch log group for workers"
  value       = aws_cloudwatch_log_group.worker_logs.name
}

output "worker_log_group_arn" {
  description = "ARN of the CloudWatch log group for workers"
  value       = aws_cloudwatch_log_group.worker_logs.arn
}

output "worker_desired_count" {
  description = "Current desired count of worker tasks"
  value       = aws_ecs_service.worker.desired_count
}

output "worker_cpu_alarm_arn" {
  description = "ARN of CPU high alarm (if enabled)"
  value       = var.enable_monitoring_alarms ? aws_cloudwatch_metric_alarm.worker_cpu_high[0].arn : null
}

output "worker_memory_alarm_arn" {
  description = "ARN of memory high alarm (if enabled)"
  value       = var.enable_monitoring_alarms ? aws_cloudwatch_metric_alarm.worker_memory_high[0].arn : null
}