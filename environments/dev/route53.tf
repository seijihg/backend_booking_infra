# Route 53 Configuration for lichnails.co.uk
module "route53" {
  source = "../../modules/route53"

  domain_name = var.domain_name
  environment = var.environment
  
  # Use the existing Route53 zone created by the registrar
  # This avoids creating duplicate zones and saves costs
  existing_zone_id = "Z025335036NRU0QL9IT2T"  # Registrar-created zone

  # Connect to your ALB
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id

  tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
}

# SSL Certificate for api-dev.lichnails.co.uk
resource "aws_acm_certificate" "backend" {
  domain_name       = "api-dev.lichnails.co.uk"
  validation_method = "DNS"

  # No additional SANs needed for now

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "backend-dev-lichnail-cert"
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
}

# DNS validation records for ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.backend.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = module.route53.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "backend" {
  certificate_arn         = aws_acm_certificate.backend.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# CNAME record for Vercel frontend - usa-berko subdomain
# Using Vercel's project-specific DNS for better routing
resource "aws_route53_record" "vercel_usa_berko" {
  zone_id = module.route53.zone_id
  name    = "usa-berko.lichnails.co.uk"
  type    = "CNAME"
  ttl     = 300
  records = ["e79677f73830cf90.vercel-dns-017.com"]
}

# Output the certificate ARN for use in ALB
output "certificate_arn" {
  description = "The ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.backend.certificate_arn
}

# Output the important DNS information
output "route53_name_servers" {
  description = "Name servers for lichnails.co.uk - Update your domain registrar with these"
  value       = module.route53.name_servers
}

output "api_dev_url" {
  description = "API development URL"
  value       = "https://api-dev.lichnails.co.uk"
}
