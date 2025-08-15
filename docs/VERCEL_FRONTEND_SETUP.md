# Vercel Frontend Configuration for lichnails.co.uk

## Overview

This guide explains how to configure your Next.js frontend on Vercel to work with:
- Frontend: `www.lichnails.co.uk` and `lichnails.co.uk`
- Backend API: `api-dev.lichnails.co.uk`

## Step 1: Deploy Frontend to Vercel

### Connect GitHub Repository

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "New Project"
3. Import your Next.js repository
4. Configure build settings:
   - Framework Preset: Next.js
   - Build Command: `npm run build` or `yarn build`
   - Output Directory: `.next`

### Environment Variables

Add these environment variables in Vercel:

```bash
# API Configuration
NEXT_PUBLIC_API_URL=https://api-dev.lichnails.co.uk

# For local development
# NEXT_PUBLIC_API_URL=http://localhost:8000
```

## Step 2: Configure Custom Domain in Vercel

### Add Domains

1. In your Vercel project, go to **Settings → Domains**
2. Add both domains:
   - `lichnails.co.uk`
   - `www.lichnails.co.uk`

### Vercel Will Provide DNS Records

Vercel will show you records like:

```
A Record for lichnails.co.uk:
Type: A
Name: @
Value: 76.76.21.21

CNAME for www.lichnails.co.uk:
Type: CNAME
Name: www
Value: cname.vercel-dns.com
```

## Step 3: Add Frontend Records to Route 53

### Manual Configuration in AWS Console

1. Go to AWS Console → Route 53 → Hosted Zones
2. Click on `lichnails.co.uk`
3. Click "Create Record"

#### Root Domain (lichnails.co.uk)

```
Record name: (leave empty)
Record type: A
Value: 76.76.21.21
TTL: 300
```

#### WWW Subdomain

```
Record name: www
Record type: CNAME
Value: cname.vercel-dns.com
TTL: 300
```

### Alternative: Using AWS CLI

```bash
# Create root domain A record
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "lichnails.co.uk",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "76.76.21.21"}]
      }
    }]
  }'

# Create www CNAME record
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "www.lichnails.co.uk",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "cname.vercel-dns.com"}]
      }
    }]
  }'
```

## Step 4: Configure Frontend API Calls

### API Service Configuration

Create `services/api.js` in your Next.js app:

```javascript
// services/api.js
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export const api = {
  // Auth endpoints
  login: async (credentials) => {
    const response = await fetch(`${API_URL}/api/auth/login/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include', // Important for CORS
      body: JSON.stringify(credentials),
    });
    return response.json();
  },

  // Booking endpoints
  getBookings: async () => {
    const response = await fetch(`${API_URL}/api/bookings/`, {
      credentials: 'include',
    });
    return response.json();
  },

  // Add more API methods as needed
};
```

### Next.js API Route Proxy (Optional)

To avoid CORS issues, you can proxy API calls through Next.js:

```javascript
// pages/api/[...path].js
export default async function handler(req, res) {
  const { path } = req.query;
  const apiPath = Array.isArray(path) ? path.join('/') : path;
  
  const apiUrl = `${process.env.BACKEND_URL}/api/${apiPath}`;
  
  const response = await fetch(apiUrl, {
    method: req.method,
    headers: {
      'Content-Type': 'application/json',
      ...req.headers,
    },
    body: req.method !== 'GET' ? JSON.stringify(req.body) : undefined,
  });
  
  const data = await response.json();
  res.status(response.status).json(data);
}
```

## Step 5: CORS Configuration for Django Backend

Ensure your Django backend allows the frontend domains:

```python
# Django settings.py
CORS_ALLOWED_ORIGINS = [
    "https://lichnails.co.uk",
    "https://www.lichnails.co.uk",
    "http://localhost:3000",  # For local development
]

# Or for development, you can use:
CORS_ALLOW_ALL_ORIGINS = True  # Only for development!
```

Update via Parameter Store:

```bash
aws ssm put-parameter \
  --name "/backend-booking/dev/app/cors-allowed-origins" \
  --value "https://lichnails.co.uk,https://www.lichnails.co.uk,http://localhost:3000" \
  --type "String" \
  --overwrite \
  --region eu-west-2
```

## Step 6: Test Your Setup

### Check DNS Resolution

```bash
# Frontend domains
nslookup www.lichnails.co.uk
nslookup lichnails.co.uk

# Backend API domain
nslookup api-dev.lichnails.co.uk
```

### Test Frontend Access

```bash
# Should redirect to Vercel
curl -I https://www.lichnails.co.uk
curl -I https://lichnails.co.uk
```

### Test API Connectivity

From browser console on your frontend:

```javascript
// Test API connection
fetch('https://api-dev.lichnails.co.uk/health/')
  .then(res => res.json())
  .then(data => console.log(data));
```

## Production Configuration

When ready for production:

### Update Environment Variables in Vercel

```bash
# Production API (future)
NEXT_PUBLIC_API_URL=https://api.lichnails.co.uk  # When production is ready
```

## Troubleshooting

### Frontend Not Loading

1. Check Vercel deployment status
2. Verify DNS records in Route 53
3. Check domain configuration in Vercel dashboard

### API Calls Failing

1. **CORS errors**: Check Django CORS settings
2. **Connection refused**: Verify backend is running
3. **SSL errors**: Ensure both frontend and backend use HTTPS

### Mixed Content Warnings

- Ensure all API calls use HTTPS
- Update any hardcoded HTTP URLs to HTTPS

## Summary

After configuration:

- **Users visit**: `www.lichnails.co.uk` → Vercel (Next.js frontend)
- **Frontend calls**: `api-dev.lichnails.co.uk` → AWS (Django backend)
- **Admin access**: `api-dev.lichnails.co.uk/admin/` → Django Admin

This separation allows:
- Independent scaling of frontend and backend
- Vercel's edge network for frontend performance
- AWS infrastructure for backend reliability
- Clear separation of concerns