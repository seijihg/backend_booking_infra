# DNS Architecture for LichNails Booking System

## Overview

The LichNails booking system uses a split architecture with the frontend hosted on Vercel and the backend API on AWS. This document outlines the DNS configuration and domain structure.

## Domain Structure

### Production Domains
- **book.lichnails.co.uk** - Customer-facing booking frontend (Vercel)
- **api.lichnails.co.uk** - Production backend API (AWS) [Future]
- **lichnails.co.uk** - Main website/landing page [Future]

### Development Domains
- **api-dev.lichnails.co.uk** - Development backend API (AWS)
- **book-dev.lichnails.co.uk** - Development frontend (Vercel) [Optional]

## DNS Management

### Route53 Hosted Zone
All DNS records for `lichnails.co.uk` are managed in AWS Route53. The hosted zone is created by Terraform and contains:

1. **NS Records** - Name servers for the domain (update at your registrar)
2. **A Record** - `api-dev.lichnails.co.uk` → AWS ALB (managed by Terraform)
3. **CNAME Record** - `book.lichnails.co.uk` → Vercel (manual setup required)

### Infrastructure Managed by Terraform
```
api-dev.lichnails.co.uk
├── Route53 A Record (Alias)
├── Points to: AWS Application Load Balancer
├── SSL Certificate: AWS ACM
└── Auto-validated via DNS
```

### Frontend Domains (Manual Setup)
```
book.lichnails.co.uk
├── Route53 CNAME Record
├── Points to: cname.vercel-dns.com
└── SSL Certificate: Managed by Vercel
```

## Setup Instructions

### 1. Update Domain Registrar
After running `terraform apply`, update your domain registrar with the Route53 name servers:
```bash
# Get name servers from Terraform output
terraform output route53_name_servers
```

### 2. Configure Backend API (Automated)
The backend API domain is fully managed by Terraform:
```bash
cd environments/dev
terraform apply
# Creates: api-dev.lichnails.co.uk → ALB
```

### 3. Configure Frontend Domain (Manual)
Add the frontend domain in Route53 console:

1. Go to Route53 → Hosted Zones → lichnails.co.uk
2. Create Record:
   - Name: `book`
   - Type: `CNAME`
   - Value: `cname.vercel-dns.com`
   - TTL: 300

4. In Vercel Dashboard:
   - Add custom domain: `book.lichnails.co.uk`
   - Vercel will automatically provision SSL

## CORS Configuration

The backend API is configured to accept requests from:
- `https://book.lichnails.co.uk` (production frontend)
- `http://localhost:3000` (local development)

These are set in:
- `allowed_hosts` - Django settings
- `CORS_ALLOWED_ORIGINS` - Environment variable

## SSL/TLS Certificates

### Backend API (AWS)
- Certificate: AWS ACM
- Domain: `api-dev.lichnails.co.uk`
- Validation: DNS (automatic via Terraform)
- Renewal: Automatic by AWS

### Frontend (Vercel)
- Certificate: Let's Encrypt (via Vercel)
- Domain: `book.lichnails.co.uk`
- Validation: Automatic by Vercel
- Renewal: Automatic by Vercel

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Route53 Hosted Zone                   │
│                     lichnails.co.uk                      │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌──────────────────┐                 ┌──────────────────┐
│ book.lichnails.  │                 │ api-dev.lichnails│
│     co.uk        │                 │     .co.uk       │
│   (CNAME)        │                 │   (A Record)     │
└──────────────────┘                 └──────────────────┘
        │                                       │
        ▼                                       ▼
┌──────────────────┐                 ┌──────────────────┐
│     Vercel       │                 │    AWS ALB       │
│   (Next.js)      │◄────API Calls───│   (Django)       │
│                  │                 │                  │
│  Frontend App    │                 │   Backend API    │
└──────────────────┘                 └──────────────────┘
```

## DNS Propagation

After making DNS changes:
- **TTL**: 300 seconds (5 minutes) for quick updates
- **Global Propagation**: Up to 48 hours
- **Testing**: Use `dig` or `nslookup` to verify:
  ```bash
  dig book.lichnails.co.uk
  dig api-dev.lichnails.co.uk
  ```

## Troubleshooting

### Frontend not accessible
1. Check CNAME record in Route53
2. Verify domain in Vercel dashboard
3. Wait for DNS propagation

### API not accessible
1. Check ALB health in AWS console
2. Verify security groups allow traffic
3. Check ECS service is running
4. Review CloudWatch logs

### CORS errors
1. Verify `CORS_ALLOWED_ORIGINS` in ECS task definition
2. Check `allowed_hosts` in Django settings
3. Ensure frontend is using correct API URL

## Future Considerations

1. **Production Setup**:
   - `api.lichnails.co.uk` for production API
   - Blue-green deployments
   - Multi-region failover

2. **Subdomains**:
   - `admin.lichnails.co.uk` - Admin panel
   - `docs.lichnails.co.uk` - API documentation
   - `status.lichnails.co.uk` - Status page

3. **CDN Integration**:
   - CloudFront for API caching
   - Vercel Edge Network for frontend