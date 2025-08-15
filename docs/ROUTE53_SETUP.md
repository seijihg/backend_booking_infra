# Route 53 Setup Guide for Backend Booking

## Overview

This guide explains how to set up Route 53 to use your registered domain name with the Backend Booking application instead of the long AWS ALB hostname.

## Current State vs. Target State

### Current State
- Application accessible at: `http://backend-booking-dev-alb-1547732208.eu-west-2.elb.amazonaws.com`
- No custom domain
- HTTP only (no HTTPS)

### Target State
- Application accessible at: `https://yourdomain.com` (or `https://dev.yourdomain.com`)
- Custom domain with SSL
- Automatic redirect from HTTP to HTTPS

## Prerequisites

1. ✅ Domain name registered (you mentioned you have this)
2. ✅ AWS account with Route 53 access
3. ✅ ALB already running (currently working)
4. ⏳ SSL certificate from AWS Certificate Manager (next step)

## Step-by-Step Implementation

### Step 1: Add Route 53 Module to Your Terraform Configuration

Edit `environments/dev/main.tf` and add:

```hcl
# Route 53 Hosted Zone and DNS Records
module "route53" {
  source = "../../modules/route53"
  
  domain_name = var.domain_name  # e.g., "yourdomain.com"
  environment = var.environment
  
  # Connect to your ALB
  alb_dns_name = module.alb.dns_name
  alb_zone_id  = module.alb.zone_id
  
  tags = local.common_tags
}
```

### Step 2: Add Domain Variable

Edit `environments/dev/variables.tf` and add:

```hcl
variable "domain_name" {
  description = "Your registered domain name"
  type        = string
}
```

### Step 3: Set Your Domain Name

Edit `environments/dev/terraform.tfvars`:

```hcl
# Add your domain
domain_name = "yourdomain.com"  # Replace with your actual domain
```

### Step 4: Request SSL Certificate (Required for HTTPS)

Add to `environments/dev/main.tf`:

```hcl
# Request SSL Certificate from AWS Certificate Manager
resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  subject_alternative_names = [
    "*.${var.domain_name}",  # Wildcard for subdomains
    "www.${var.domain_name}"
  ]
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = local.common_tags
}

# DNS validation record for ACM
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
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
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
```

### Step 5: Update ALB for HTTPS

Modify your ALB module call in `environments/dev/main.tf`:

```hcl
module "alb" {
  source = "../../modules/alb"
  
  # ... existing configuration ...
  
  # Add HTTPS listener
  certificate_arn = aws_acm_certificate_validation.main.certificate_arn
  
  # Enable redirect from HTTP to HTTPS
  enable_https_redirect = true
}
```

### Step 6: Deploy the Infrastructure

```bash
cd environments/dev

# Plan the changes
terraform plan

# Apply the changes
terraform apply
```

### Step 7: Update Domain Registrar Name Servers

After Terraform creates the hosted zone, you'll see output with 4 name servers:

```
Outputs:
route53_name_servers = [
  "ns-123.awsdns-12.com",
  "ns-456.awsdns-34.net",
  "ns-789.awsdns-56.org",
  "ns-012.awsdns-78.co.uk"
]
```

**Update your domain registrar** (GoDaddy, Namecheap, etc.):
1. Log into your domain registrar account
2. Find DNS/Name Server settings
3. Change from default name servers to "Custom"
4. Enter the 4 Route 53 name servers
5. Save changes

### Step 8: Verify DNS Propagation

DNS changes can take 15 minutes to 48 hours. Check status:

```bash
# Check if Route 53 name servers are active
nslookup -type=NS yourdomain.com

# Check if domain points to ALB
nslookup yourdomain.com

# Test the domain (once propagated)
curl https://yourdomain.com/health/
```

## DNS Records Created

The module will create these DNS records:

| URL | Purpose |
|-----|---------|
| `yourdomain.com` | Main application |
| `www.yourdomain.com` | WWW version |
| `dev.yourdomain.com` | Development environment |
| `api.yourdomain.com` | API endpoint |

## Update Django Settings

Don't forget to update your Django `ALLOWED_HOSTS`:

```python
# In your Django settings
ALLOWED_HOSTS = [
    'yourdomain.com',
    'www.yourdomain.com',
    'dev.yourdomain.com',
    'api.yourdomain.com',
    'backend-booking-dev-alb-1547732208.eu-west-2.elb.amazonaws.com',  # Keep ALB hostname
    'localhost',
]
```

Update this in Parameter Store:
```bash
aws ssm put-parameter \
  --name "/backend-booking/dev/app/allowed-hosts" \
  --value "yourdomain.com,www.yourdomain.com,dev.yourdomain.com,api.yourdomain.com" \
  --type "String" \
  --overwrite
```

## Testing Your Domain

Once DNS propagates:

1. **Test HTTP redirect to HTTPS**:
   ```bash
   curl -I http://yourdomain.com
   # Should show 301 redirect to https://
   ```

2. **Test HTTPS**:
   ```bash
   curl https://yourdomain.com/health/
   # Should return 200 OK
   ```

3. **Test subdomains**:
   ```bash
   curl https://dev.yourdomain.com/health/
   curl https://api.yourdomain.com/health/
   ```

## Troubleshooting

### DNS Not Resolving
- Verify name servers are updated at registrar
- Wait for propagation (up to 48 hours)
- Check with: `dig +trace yourdomain.com`

### Certificate Issues
- Ensure DNS validation records are created
- Certificate must be in `us-east-1` for CloudFront
- Certificate must be in same region as ALB for ALB

### HTTPS Not Working
- Verify certificate is validated (green in ACM console)
- Check ALB listener is configured for port 443
- Ensure security groups allow port 443

## Cost Implications

- **Route 53 Hosted Zone**: $0.50/month
- **DNS Queries**: $0.40 per million queries
- **ACM Certificate**: Free
- **No additional ALB costs** for HTTPS

## Next Steps

1. **Add CloudFront CDN** for static files
2. **Set up health checks** in Route 53
3. **Configure subdomain** for staging/production
4. **Add MX records** for email if needed

## Summary

Route 53 Hosted Zone acts as the authoritative DNS server for your domain, replacing your registrar's basic DNS with AWS's globally distributed, highly available DNS service. It enables you to use your custom domain instead of the AWS-generated ALB hostname.