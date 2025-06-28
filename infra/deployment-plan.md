# Google Cloud Deployment Plan - Next.js Medusa Storefront

## Overview

This deployment plan outlines the infrastructure and configuration needed to deploy the Next.js 15 Medusa v2 storefront on Google Cloud Platform using Terraform.

## Architecture Components

### 1. Application Hosting
- **Cloud Run**: Containerized Next.js application
  - Auto-scaling based on traffic
  - Pay-per-use pricing
  - Built-in load balancing
  - HTTPS termination

### 2. Database Layer
- **Cloud SQL (PostgreSQL)**: Medusa backend database
  - High availability configuration
  - Automated backups
  - Read replicas for performance

### 3. Storage
- **Cloud Storage**: Static assets and media files
  - CDN integration via Cloud CDN
  - Multi-regional storage for global access

### 4. Networking
- **Cloud Load Balancer**: Global HTTP(S) load balancer
- **Cloud CDN**: Global content delivery network
- **VPC Network**: Secure network isolation

### 5. Monitoring & Logging
- **Cloud Monitoring**: Application and infrastructure metrics
- **Cloud Logging**: Centralized log management
- **Error Reporting**: Application error tracking

## Prerequisites

### Required Tools
- Terraform >= 1.0
- Google Cloud CLI (`gcloud`)
- Docker
- Node.js 18+
- Yarn

### GCP Setup
1. Create or select a GCP project
2. Enable required APIs:
   ```bash
   gcloud services enable run.googleapis.com
   gcloud services enable sql-component.googleapis.com
   gcloud services enable storage.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable compute.googleapis.com
   ```
3. Create service account with required permissions
4. Download service account key

## Environment Configuration

### Required Environment Variables
```bash
# GCP Configuration
export GOOGLE_PROJECT_ID="your-project-id"
export GOOGLE_REGION="us-central1"
export GOOGLE_ZONE="us-central1-a"

# Application Configuration
export MEDUSA_BACKEND_URL="https://your-medusa-backend.run.app"
export NEXT_PUBLIC_BASE_URL="https://your-storefront.run.app"
export NEXT_PUBLIC_DEFAULT_REGION="us"
export NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY="pk_your_key"
export NEXT_PUBLIC_STRIPE_KEY="pk_test_your_stripe_key"

# Database Configuration
export DB_HOST="your-sql-instance-ip"
export DB_NAME="medusa"
export DB_USER="medusa"
export DB_PASSWORD="secure_password"
```

## Terraform Infrastructure

### Directory Structure
```
infra/
├── terraform/
│   ├── main.tf              # Main configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── providers.tf         # Provider configuration
│   ├── modules/
│   │   ├── cloud-run/       # Cloud Run module
│   │   ├── cloud-sql/       # Cloud SQL module
│   │   ├── storage/         # Cloud Storage module
│   │   └── networking/      # VPC and Load Balancer
│   └── environments/
│       ├── dev/
│       ├── staging/
│       └── production/
├── docker/
│   └── Dockerfile           # Container definition
└── scripts/
    ├── deploy.sh            # Deployment script
    └── setup.sh             # Initial setup script
```

### Key Terraform Resources

#### Cloud Run Service
```hcl
resource "google_cloud_run_service" "storefront" {
  name     = "nextjs-storefront"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/nextjs-storefront:latest"
        
        ports {
          container_port = 8000
        }

        env {
          name  = "MEDUSA_BACKEND_URL"
          value = var.medusa_backend_url
        }
        
        resources {
          limits = {
            cpu    = "2000m"
            memory = "4Gi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "100"
        "run.googleapis.com/cpu-throttling" = "false"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}
```

#### Cloud SQL Instance
```hcl
resource "google_sql_database_instance" "postgres" {
  name             = "medusa-postgres"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-f1-micro"  # Adjust based on needs
    
    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.vpc.id
    }
  }
}
```

#### Cloud Storage Bucket
```hcl
resource "google_storage_bucket" "assets" {
  name     = "${var.project_id}-storefront-assets"
  location = "US"

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}
```

## Deployment Process

### 1. Initial Setup
```bash
# Clone repository
git clone <repository-url>
cd nextjs-starter-medusa

# Setup GCP authentication
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Initialize Terraform
cd infra/terraform
terraform init
```

### 2. Infrastructure Deployment
```bash
# Plan deployment
terraform plan -var-file="environments/production/terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="environments/production/terraform.tfvars"
```

### 3. Application Deployment
```bash
# Build and push container
docker build -t gcr.io/YOUR_PROJECT_ID/nextjs-storefront:latest .
docker push gcr.io/YOUR_PROJECT_ID/nextjs-storefront:latest

# Deploy to Cloud Run
gcloud run deploy nextjs-storefront \
  --image gcr.io/YOUR_PROJECT_ID/nextjs-storefront:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

## Performance Optimization

### Caching Strategy
- **Cloud CDN**: Cache static assets globally
- **Application-level**: Next.js built-in caching
- **Database**: Read replicas for improved performance

### Scaling Configuration
- **Horizontal scaling**: Auto-scale Cloud Run instances
- **Database scaling**: Vertical scaling for Cloud SQL
- **CDN**: Global edge locations

## Security Considerations

### Network Security
- VPC with private subnets for database
- Cloud NAT for outbound internet access
- Firewall rules for restricted access

### Application Security
- HTTPS enforced via Cloud Load Balancer
- Environment variables via Secret Manager
- IAM roles with least privilege

### Database Security
- Private IP configuration
- Automated security patches
- Encrypted at rest and in transit

## Monitoring and Alerting

### Metrics to Monitor
- Application response times
- Error rates
- Database performance
- Resource utilization

### Alerting Rules
- High error rates (>5%)
- Response time > 2 seconds
- Database connection issues
- Resource exhaustion

## Cost Optimization

### Resource Sizing
- Start with minimal resources and scale up
- Use preemptible instances where possible
- Implement auto-scaling policies

### Cost Controls
- Set up billing alerts
- Use committed use discounts
- Regular resource utilization reviews

## Backup and Disaster Recovery

### Database Backups
- Automated daily backups
- Point-in-time recovery
- Cross-region backup replication

### Application Recovery
- Infrastructure as Code for quick rebuilds
- Container images stored in multiple regions
- Health checks and automatic failover

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Deploy to GCP
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup GCP
        uses: google-github-actions/setup-gcloud@v1
      - name: Build and Deploy
        run: |
          docker build -t gcr.io/$PROJECT_ID/app:$GITHUB_SHA .
          docker push gcr.io/$PROJECT_ID/app:$GITHUB_SHA
          gcloud run deploy app --image gcr.io/$PROJECT_ID/app:$GITHUB_SHA
```

## Environment-Specific Configurations

### Development
- Smaller instance sizes
- Single region deployment
- Basic monitoring

### Staging
- Production-like configuration
- Limited scaling
- Full monitoring suite

### Production
- High availability setup
- Multi-region deployment
- Comprehensive monitoring and alerting

## Troubleshooting Guide

### Common Issues
1. **Cold start latency**: Implement keep-alive requests
2. **Database connection limits**: Use connection pooling
3. **Build failures**: Check Node.js version compatibility
4. **Environment variables**: Verify Secret Manager configuration

### Debug Commands
```bash
# Check Cloud Run logs
gcloud logging read "resource.type=cloud_run_revision"

# Monitor resource usage
gcloud monitoring metrics list

# Test database connectivity
gcloud sql connect INSTANCE_NAME --user=USERNAME
```

## Next Steps

1. Review and customize Terraform configurations
2. Set up monitoring dashboards
3. Configure CI/CD pipelines
4. Implement security best practices
5. Performance testing and optimization
6. Documentation for operations team