# ECS Task Definition Module Outputs

output "task_definition_arn" {
  description = "Full ARN of the task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_arn_without_revision" {
  description = "ARN of the task definition without revision"
  value       = aws_ecs_task_definition.app.arn_without_revision
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.app.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.app.revision
}

output "container_name" {
  description = "Name of the container"
  value       = var.container_name
}

output "container_port" {
  description = "Port the container listens on"
  value       = var.container_port
}

output "task_cpu" {
  description = "CPU units allocated to the task"
  value       = var.task_cpu
}

output "task_memory" {
  description = "Memory allocated to the task"
  value       = var.task_memory
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = var.execution_role_arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = var.task_role_arn
}