# Production Environment Configuration

# Project Configuration
project_id  = "your-gcp-project-id"
region      = "us-central1"
zone        = "us-central1-a"
environment = "production"

# Application Configuration
app_name                     = "nextjs-storefront"
medusa_backend_url          = "https://your-medusa-backend.run.app"
next_public_base_url        = "https://your-storefront.com"
next_public_default_region  = "us"

# Secrets (set these via environment variables or separate .tfvars file)
# medusa_publishable_key = "pk_live_your_key"
# stripe_public_key     = "pk_live_your_stripe_key"
# db_password           = "secure_production_password"

# Database Configuration (larger for production)
db_tier     = "db-custom-4-16384"  # 4 vCPUs, 16GB RAM
db_name     = "medusa"
db_user     = "medusa"

# Cloud Run Configuration (larger for production)
cloud_run_cpu       = "4000m"
cloud_run_memory    = "8Gi"
cloud_run_max_scale = 1000
cloud_run_min_scale = 2

# Storage Configuration
storage_location = "US"

# Networking
enable_vpc = true
vpc_cidr   = "10.2.0.0/16"