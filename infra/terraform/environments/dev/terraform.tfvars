# Development Environment Configuration

# Project Configuration
project_id  = "your-gcp-project-id"
region      = "us-central1"
zone        = "us-central1-a"
environment = "dev"

# Application Configuration
app_name                     = "nextjs-storefront"
medusa_backend_url          = "https://your-dev-medusa-backend.run.app"
next_public_base_url        = "https://your-dev-storefront.run.app"
next_public_default_region  = "us"

# Secrets (set these via environment variables or separate .tfvars file)
# medusa_publishable_key = "pk_dev_your_key"
# stripe_public_key     = "pk_test_your_stripe_key"
# db_password           = "secure_dev_password"

# Database Configuration (smaller for dev)
db_tier     = "db-f1-micro"
db_name     = "medusa_dev"
db_user     = "medusa"

# Cloud Run Configuration (smaller for dev)
cloud_run_cpu       = "1000m"
cloud_run_memory    = "2Gi"
cloud_run_max_scale = 10
cloud_run_min_scale = 0

# Storage Configuration
storage_location = "US"

# Networking
enable_vpc = true
vpc_cidr   = "10.0.0.0/16"