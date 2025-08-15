# Route 53 Module

This module creates and manages a Route 53 hosted zone with DNS records for the Backend Booking application.

## What is a Route 53 Hosted Zone?

A hosted zone is a container for DNS records for a domain. It tells DNS resolvers how to respond to DNS queries for your domain.

## Features

- Creates hosted zone for your domain
- Sets up A records for root domain and subdomains
- Supports alias records for ALB and CloudFront
- Environment-specific subdomains (dev.domain.com, staging.domain.com)
- API and static content subdomains

## Usage

```hcl
module "route53" {
  source = "../../modules/route53"

  domain_name = "yourdomain.com"
  environment = "dev"
  
  # ALB configuration
  alb_dns_name = module.alb.dns_name
  alb_zone_id  = module.alb.zone_id
  
  # Optional: CloudFront for static content
  cloudfront_domain_name = module.cloudfront.domain_name
  cloudfront_zone_id     = module.cloudfront.hosted_zone_id
  
  tags = local.common_tags
}
```

## DNS Records Created

For a domain like `example.com` in `dev` environment:

| Record | Type | Points To | Purpose |
|--------|------|-----------|---------|
| example.com | A (Alias) | ALB | Main application |
| www.example.com | A (Alias) | ALB | WWW redirect |
| dev.example.com | A (Alias) | ALB | Dev environment |
| api.example.com | A (Alias) | ALB | API endpoint |
| static.example.com | A (Alias) | CloudFront | Static assets (optional) |

## Setup Steps

### 1. Create the Hosted Zone

Deploy this module with Terraform:
```bash
terraform apply
```

### 2. Update Your Domain Registrar

After creating the hosted zone, you'll get 4 name servers. Update your domain registrar (GoDaddy, Namecheap, etc.) to use these Route 53 name servers:

Example name servers:
- ns-123.awsdns-12.com
- ns-456.awsdns-34.net
- ns-789.awsdns-56.org
- ns-012.awsdns-78.co.uk

### 3. Verify DNS Propagation

Check if DNS is working (may take up to 48 hours):
```bash
# Check name servers
dig +short NS yourdomain.com

# Check A record
dig +short A yourdomain.com

# Check specific subdomain
dig +short A dev.yourdomain.com
```

## Important Notes

1. **Name Server Update**: You must update your domain registrar to point to Route 53 name servers
2. **Propagation Time**: DNS changes can take up to 48 hours to propagate globally
3. **TTL**: Default TTL is 300 seconds (5 minutes) for faster updates
4. **Health Checks**: ALB alias records include automatic health checking
5. **SSL Certificate**: You'll need an ACM certificate for HTTPS (see SSL module)

## Cost

- Hosted Zone: $0.50 per month
- Queries: $0.40 per million queries
- Health Checks: $0.50 per health check per month (optional)

## Outputs

- `zone_id`: Use this to add more DNS records
- `name_servers`: Provide these to your domain registrar
- `domain_name`: The full domain name
- `root_record`: The main domain A record
- `environment_record`: Environment-specific subdomain (dev.domain.com)