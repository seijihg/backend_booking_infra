output "zone_id" {
  description = "The hosted zone ID"
  value       = local.zone_id
}

output "name_servers" {
  description = "List of name servers for the hosted zone"
  value       = local.zone_name_servers
}

output "domain_name" {
  description = "The domain name of the hosted zone"
  value       = local.zone_name
}

output "api_dev_record" {
  description = "The API development subdomain"
  value       = var.environment == "dev" ? aws_route53_record.api_dev[0].fqdn : null
}