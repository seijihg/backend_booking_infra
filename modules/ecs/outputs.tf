# ECS Cluster Outputs
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# ECS Service Outputs
output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.app.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "service_desired_count" {
  description = "Desired count of the ECS service"
  value       = aws_ecs_service.app.desired_count
}

# Task Definition Outputs
output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.app.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.app.revision
}

# IAM Role Outputs
output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.ecs_task.arn
}

# Security Group Outputs
output "ecs_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = local.ecs_tasks_sg_id
}

# CloudWatch Log Group Outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

# Auto Scaling Outputs
output "autoscaling_target_resource_id" {
  description = "Resource ID of the auto scaling target"
  value       = aws_appautoscaling_target.ecs.resource_id
}

output "autoscaling_min_capacity" {
  description = "Minimum capacity for auto scaling"
  value       = aws_appautoscaling_target.ecs.min_capacity
}

output "autoscaling_max_capacity" {
  description = "Maximum capacity for auto scaling"
  value       = aws_appautoscaling_target.ecs.max_capacity
}

# CloudWatch Alarm Outputs
output "cpu_alarm_arn" {
  description = "ARN of the CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
}

output "memory_alarm_arn" {
  description = "ARN of the memory utilization alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
}

output "task_count_alarm_arn" {
  description = "ARN of the running task count alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_running_tasks_low.arn
}