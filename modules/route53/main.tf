# Use existing Route 53 Hosted Zone (created by registrar or manually)
# Zone ID must be provided if multiple zones exist with the same name
data "aws_route53_zone" "main" {
  count = var.existing_zone_id == "" ? 1 : 0
  name  = var.domain_name
}

# Use specific zone when ID is provided
data "aws_route53_zone" "specific" {
  count   = var.existing_zone_id != "" ? 1 : 0
  zone_id = var.existing_zone_id
}

# Local value to get the correct zone
locals {
  zone_id = var.existing_zone_id != "" ? data.aws_route53_zone.specific[0].zone_id : data.aws_route53_zone.main[0].zone_id
  zone_name_servers = var.existing_zone_id != "" ? data.aws_route53_zone.specific[0].name_servers : data.aws_route53_zone.main[0].name_servers
  zone_name = var.existing_zone_id != "" ? data.aws_route53_zone.specific[0].name : data.aws_route53_zone.main[0].name
}

# API dev subdomain (api-dev.lichnails.co.uk) - for development
resource "aws_route53_record" "api_dev" {
  count = var.environment == "dev" ? 1 : 0

  zone_id = local.zone_id
  name    = "api-dev.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
