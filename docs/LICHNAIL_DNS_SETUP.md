# DNS Setup Guide for lichnails.co.uk

## Domain Structure Overview

Your domain `lichnails.co.uk` will be configured as follows:

| Subdomain | Purpose | Hosted On | Managed By |
|-----------|---------|-----------|------------|
| `lichnails.co.uk` | Frontend (Next.js) | Vercel | Manual Route 53 / Vercel |
| `www.lichnails.co.uk` | Frontend (Next.js) | Vercel | Manual Route 53 / Vercel |
| `api-dev.lichnails.co.uk` | API Dev Endpoint (Django) | AWS ECS | Terraform |

## Step 1: Deploy Route 53 with Terraform

### Deploy the Infrastructure

```bash
cd environments/dev

# Initialize if not already done
terraform init

# Plan the changes
terraform plan

# Apply to create Route 53 hosted zone
terraform apply
```

### Save the Name Servers

After deployment, Terraform will output 4 name servers like:
```
route53_name_servers = [
  "ns-123.awsdns-12.com",
  "ns-456.awsdns-34.net",
  "ns-789.awsdns-56.org",
  "ns-012.awsdns-78.co.uk"
]
```

**IMPORTANT: Save these name servers!**

## Step 2: Update Domain Registrar

### Where to Update

Go to where you registered `lichnails.co.uk`:
- GoDaddy
- Namecheap
- 123-reg
- Or your domain registrar

### Update Name Servers

1. Log into your domain registrar account
2. Find your domain `lichnails.co.uk`
3. Look for "DNS Settings" or "Name Servers"
4. Change from default to "Custom Name Servers"
5. Enter the 4 Route 53 name servers from Step 1
6. Save changes

**Note**: DNS propagation takes 15 minutes to 48 hours

## Step 3: Configure Frontend (Vercel) DNS

You have two options for the frontend:

### Option A: Configure in Vercel (Recommended)

1. **In Vercel Dashboard**:
   - Go to your Next.js project
   - Go to Settings → Domains
   - Add `lichnails.co.uk` and `www.lichnails.co.uk`
   - Vercel will provide DNS records to add

2. **In AWS Route 53 Console**:
   - Go to Route 53 → Hosted Zones → lichnails.co.uk
   - Add the records Vercel provides:
   
   ```
   Type: A
   Name: lichnails.co.uk (leave empty for root)
   Value: 76.76.21.21 (Vercel's IP)
   
   Type: CNAME
   Name: www
   Value: cname.vercel-dns.com
   ```

### Option B: Manual Route 53 Configuration

If you know your Vercel deployment URL:

1. **In AWS Route 53 Console**:
   ```
   # Root domain
   Type: CNAME
   Name: (leave empty)
   Value: your-app.vercel.app
   
   # WWW subdomain
   Type: CNAME
   Name: www
   Value: your-app.vercel.app
   ```

## Step 4: Update ALB for HTTPS (Backend)

The ALB module needs updating to support HTTPS. Add to `environments/dev/main.tf`:

```hcl
# Update the ALB module call
module "alb" {
  source = "../../modules/alb"
  
  # ... existing configuration ...
  
  # Add HTTPS support
  certificate_arn = aws_acm_certificate_validation.backend.certificate_arn
  
  # This will need to be added to the ALB module
  enable_https = true
  enable_http_redirect = true
}
```

## Step 5: Update Django Settings

### Update ALLOWED_HOSTS

The Django application needs to accept requests from the new domains:

```bash
# Update Parameter Store
aws ssm put-parameter \
  --name "/backend-booking/dev/app/allowed-hosts" \
  --value "api-dev.lichnails.co.uk,localhost,127.0.0.1" \
  --type "String" \
  --overwrite \
  --region eu-west-2
```

### Update CORS Settings (for frontend-backend communication)

```bash
# Add CORS allowed origins for your frontend
aws ssm put-parameter \
  --name "/backend-booking/dev/app/cors-allowed-origins" \
  --value "https://www.lichnails.co.uk,https://lichnails.co.uk,http://localhost:3000" \
  --type "String" \
  --region eu-west-2
```

## Step 6: Test Your Configuration

### Check DNS Propagation

```bash
# Check name servers are updated
nslookup -type=NS lichnails.co.uk

# Check API subdomain
nslookup api-dev.lichnails.co.uk

# Check if pointing to ALB
dig api-dev.lichnails.co.uk
```

### Test Backend Access

Once DNS propagates:

```bash
# Test API health endpoint
curl https://api-dev.lichnails.co.uk/health/

# Test Django admin
curl https://api-dev.lichnails.co.uk/admin/
```

### Test Frontend Access

```bash
# Test root domain
curl https://lichnails.co.uk

# Test www
curl https://www.lichnails.co.uk
```

## Frontend API Configuration

In your Next.js application, update the API endpoint:

```javascript
// .env.local or environment configuration
NEXT_PUBLIC_API_URL=https://api-dev.lichnails.co.uk

// For production later:
// NEXT_PUBLIC_API_URL=https://api.lichnails.co.uk
```

## Troubleshooting

### DNS Not Resolving

1. **Check propagation status**:
   - Use https://www.whatsmydns.net/
   - Enter `lichnails.co.uk` to check global propagation

2. **Verify name servers**:
   ```bash
   dig +trace lichnails.co.uk
   ```

### Certificate Issues

1. **Check certificate status**:
   - AWS Console → Certificate Manager
   - Should show "Issued" status

2. **Validation records**:
   - Ensure DNS validation records are created
   - Check Route 53 for CNAME validation records

### Frontend Can't Connect to Backend

1. **CORS Issues**:
   - Check Django CORS settings
   - Ensure frontend domain is in allowed origins

2. **HTTPS Mixed Content**:
   - Both frontend and backend must use HTTPS
   - Check browser console for mixed content warnings

## Domain Summary

After setup, you'll have:

- **Frontend**: `https://www.lichnails.co.uk` (Vercel-hosted Next.js)
- **API Dev**: `https://api-dev.lichnails.co.uk` (AWS-hosted Django API & Admin)

## Next Steps

1. ✅ Deploy Route 53 with Terraform
2. ✅ Update domain registrar name servers
3. ⏳ Wait for DNS propagation (15 mins - 48 hours)
4. 🔧 Configure Vercel domains
5. 🔧 Update ALB for HTTPS support
6. 🔧 Test all endpoints
7. 🚀 Deploy frontend to Vercel
8. 🎉 Your full-stack app is live!

## Important Notes

- **DNS Propagation**: Can take up to 48 hours globally
- **SSL Certificates**: Automatically managed by AWS ACM for backend, Vercel for frontend
- **Costs**: Route 53 hosted zone costs $0.50/month + $0.40 per million queries
- **Vercel Limits**: Free tier includes SSL and custom domains