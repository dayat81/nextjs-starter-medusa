# Infrastructure Documentation

This directory contains all the infrastructure code and deployment configurations for deploying the Next.js Medusa Storefront on Google Cloud Platform.

## Directory Structure

```
infra/
├── deployment-plan.md          # Comprehensive deployment guide
├── terraform/                  # Terraform infrastructure code
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   ├── providers.tf           # Provider configurations
│   ├── modules/               # Reusable Terraform modules
│   │   ├── cloud-run/         # Cloud Run service module
│   │   ├── cloud-sql/         # PostgreSQL database module
│   │   ├── storage/           # Cloud Storage and CDN module
│   │   └── networking/        # VPC and networking module
│   └── environments/          # Environment-specific configurations
│       ├── dev/               # Development environment
│       ├── staging/           # Staging environment
│       └── production/        # Production environment
├── docker/                    # Docker configurations
│   ├── Dockerfile             # Multi-stage Docker build
│   └── .dockerignore          # Docker build exclusions
└── scripts/                   # Deployment automation scripts
    ├── setup.sh               # Initial GCP setup script
    └── deploy.sh              # Deployment automation script
```

## Quick Start

### 1. Initial Setup

Run the setup script to configure your GCP project:

```bash
chmod +x infra/scripts/setup.sh
./infra/scripts/setup.sh
```

This script will:
- Check prerequisites (gcloud, terraform, docker)
- Enable required GCP APIs
- Create Terraform state bucket
- Set up service accounts and IAM roles
- Initialize Terraform configuration

### 2. Configure Environment

Update the configuration files for your target environment:

```bash
# Edit main configuration
vim infra/terraform/environments/dev/terraform.tfvars

# Edit secrets configuration
vim infra/terraform/environments/dev/secrets.tfvars
```

### 3. Deploy Infrastructure

Use the deployment script to deploy your infrastructure:

```bash
# Plan deployment (dry run)
./infra/scripts/deploy.sh dev plan

# Apply deployment
./infra/scripts/deploy.sh dev apply

# For production
./infra/scripts/deploy.sh production apply
```

## Architecture Overview

The infrastructure deploys the following components:

### Core Services
- **Cloud Run**: Containerized Next.js application with auto-scaling
- **Cloud SQL**: PostgreSQL database for Medusa backend
- **Cloud Storage**: Static assets and CDN distribution
- **VPC Network**: Secure networking with private database access

### Supporting Services
- **Secret Manager**: Secure storage for API keys and passwords
- **Cloud Build**: Automated container builds and deployments
- **Cloud Monitoring**: Application and infrastructure monitoring
- **Cloud Logging**: Centralized log management

### Security Features
- Private VPC network for database isolation
- IAM service accounts with least privilege access
- Encrypted data at rest and in transit
- HTTPS enforcement for all traffic

## Environment Configurations

### Development (`dev`)
- Minimal resource allocation for cost optimization
- Single-zone deployment
- Basic monitoring and logging
- Suitable for development and testing

### Staging (`staging`)
- Production-like configuration
- Regional high availability
- Full monitoring suite
- Pre-production testing environment

### Production (`production`)
- High availability multi-zone deployment
- Maximum resource allocation
- Comprehensive monitoring and alerting
- Automated backups and disaster recovery

## Monitoring and Maintenance

### Health Checks
- Application health endpoint: `/api/health`
- Database connectivity monitoring
- Resource utilization tracking

### Backup Strategy
- Automated daily database backups
- Point-in-time recovery capability
- Cross-region backup replication for production

### Scaling
- Automatic horizontal scaling based on traffic
- Configurable min/max instance limits
- Database vertical scaling as needed

## CI/CD Integration

The GitHub Actions workflow (`.github/workflows/deploy.yml`) provides:
- Automated testing on pull requests
- Branch-based environment deployment
- Security scanning with Trivy
- Deployment status notifications

### Required Secrets

Set these secrets in your GitHub repository:

```
GCP_PROJECT_ID          # Your GCP project ID
GCP_SA_KEY              # Service account key (JSON)
MEDUSA_BACKEND_URL      # Medusa backend URL
NEXT_PUBLIC_BASE_URL    # Storefront public URL
MEDUSA_PUBLISHABLE_KEY  # Medusa API key
STRIPE_PUBLIC_KEY       # Stripe public key (optional)
DB_PASSWORD             # Database password
```

## Troubleshooting

### Common Issues

1. **API Not Enabled**: Ensure all required GCP APIs are enabled
2. **Permission Denied**: Check service account IAM roles
3. **Build Failures**: Verify Node.js version and dependencies
4. **Database Connection**: Check VPC network configuration

### Debug Commands

```bash
# Check Cloud Run logs
gcloud logging read "resource.type=cloud_run_revision" --limit=50

# Monitor resource usage
gcloud monitoring metrics list

# Test database connectivity
gcloud sql connect INSTANCE_NAME --user=medusa

# Check Terraform state
cd infra/terraform && terraform show
```

### Getting Help

1. Check the deployment plan: `infra/deployment-plan.md`
2. Review Terraform outputs: `terraform output`
3. Check application logs in Google Cloud Console
4. Verify environment configuration files

## Cost Optimization

### Development
- Use smaller instance sizes (`db-f1-micro`, `1000m` CPU)
- Enable auto-scaling to zero when not in use
- Use single-zone deployment

### Production
- Monitor resource usage and adjust accordingly
- Use committed use discounts for predictable workloads
- Implement lifecycle policies for storage buckets
- Set up billing alerts and budget controls

## Security Best Practices

1. **Secrets Management**: Use Secret Manager for all sensitive data
2. **Network Security**: Keep databases in private VPC
3. **Access Control**: Use service accounts with minimal permissions
4. **Monitoring**: Enable audit logging and monitoring
5. **Updates**: Keep all dependencies and base images updated

## Next Steps

After successful deployment:

1. Configure custom domain and SSL certificates
2. Set up monitoring dashboards and alerts
3. Implement backup and disaster recovery procedures
4. Configure CI/CD pipeline for automated deployments
5. Set up staging environment for testing
6. Document operational procedures for your team