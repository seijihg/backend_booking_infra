# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge(
    var.tags,
    {
      Name        = var.domain_name
      Environment = var.environment
    }
  )
}

# API dev subdomain (api-dev.lichnails.co.uk) - for development
resource "aws_route53_record" "api_dev" {
  count = var.environment == "dev" ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = "api-dev.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
