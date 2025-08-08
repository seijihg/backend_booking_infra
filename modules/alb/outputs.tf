# ALB Module Outputs

# Load Balancer Outputs
output "alb_id" {
  description = "The ID of the load balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the load balancer (for Route53 alias records)"
  value       = aws_lb.main.zone_id
}

# Target Group Outputs
output "target_group_id" {
  description = "The ID of the target group"
  value       = aws_lb_target_group.main.id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "target_group_arn_suffix" {
  description = "The ARN suffix for use with CloudWatch Metrics"
  value       = aws_lb_target_group.main.arn_suffix
}

output "target_group_name" {
  description = "The name of the target group"
  value       = aws_lb_target_group.main.name
}

# Listener Outputs
output "http_listener_arn" {
  description = "The ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener"
  value       = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : null
}

# CloudWatch Alarm Outputs
output "response_time_alarm_id" {
  description = "The ID of the response time alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.target_response_time[0].id : null
}

output "unhealthy_hosts_alarm_id" {
  description = "The ID of the unhealthy hosts alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.unhealthy_host_count[0].id : null
}

output "error_rate_alarm_id" {
  description = "The ID of the 5xx error rate alarm"
  value       = var.enable_alarms ? aws_cloudwatch_metric_alarm.http_5xx_count[0].id : null
}

# URL Output
output "alb_url" {
  description = "The URL of the load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}