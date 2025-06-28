# Staging Environment Configuration

# Project Configuration
project_id  = "your-gcp-project-id"
region      = "us-central1"
zone        = "us-central1-a"
environment = "staging"

# Application Configuration
app_name                     = "nextjs-storefront"
medusa_backend_url          = "https://your-staging-medusa-backend.run.app"
next_public_base_url        = "https://your-staging-storefront.run.app"
next_public_default_region  = "us"

# Secrets (set these via environment variables or separate .tfvars file)
# medusa_publishable_key = "pk_staging_your_key"
# stripe_public_key     = "pk_test_your_stripe_key"
# db_password           = "secure_staging_password"

# Database Configuration (medium size for staging)
db_tier     = "db-g1-small"
db_name     = "medusa_staging"
db_user     = "medusa"

# Cloud Run Configuration (medium size for staging)
cloud_run_cpu       = "2000m"
cloud_run_memory    = "4Gi"
cloud_run_max_scale = 50
cloud_run_min_scale = 1

# Storage Configuration
storage_location = "US"

# Networking
enable_vpc = true
vpc_cidr   = "10.1.0.0/16"