# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ])

  service = each.value
  project = var.project_id

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Random suffix for unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name_suffix = random_id.suffix.hex
  common_labels = {
    environment = var.environment
    application = var.app_name
    managed_by  = "terraform"
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  name_suffix   = local.name_suffix
  vpc_cidr      = var.vpc_cidr
  enable_vpc    = var.enable_vpc
  
  labels = local.common_labels
  
  depends_on = [google_project_service.required_apis]
}

# Storage Module
module "storage" {
  source = "./modules/storage"
  
  project_id       = var.project_id
  environment      = var.environment
  name_suffix      = local.name_suffix
  storage_location = var.storage_location
  
  labels = local.common_labels
  
  depends_on = [google_project_service.required_apis]
}

# Cloud SQL Module
module "cloud_sql" {
  source = "./modules/cloud-sql"
  
  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  name_suffix   = local.name_suffix
  
  db_tier     = var.db_tier
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
  
  vpc_network = module.networking.vpc_network
  
  labels = local.common_labels
  
  depends_on = [
    google_project_service.required_apis,
    module.networking
  ]
}

# Secrets Management
resource "google_secret_manager_secret" "medusa_publishable_key" {
  secret_id = "${var.app_name}-medusa-key-${local.name_suffix}"
  
  replication {
    auto {}
  }
  
  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "medusa_publishable_key" {
  secret      = google_secret_manager_secret.medusa_publishable_key.id
  secret_data = var.medusa_publishable_key
}

resource "google_secret_manager_secret" "stripe_key" {
  count     = var.stripe_public_key != "" ? 1 : 0
  secret_id = "${var.app_name}-stripe-key-${local.name_suffix}"
  
  replication {
    auto {}
  }
  
  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "stripe_key" {
  count       = var.stripe_public_key != "" ? 1 : 0
  secret      = google_secret_manager_secret.stripe_key[0].id
  secret_data = var.stripe_public_key
}

# Cloud Run Module
module "cloud_run" {
  source = "./modules/cloud-run"
  
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  name_suffix  = local.name_suffix
  
  app_name     = var.app_name
  
  # Resource allocation
  cpu        = var.cloud_run_cpu
  memory     = var.cloud_run_memory
  max_scale  = var.cloud_run_max_scale
  min_scale  = var.cloud_run_min_scale
  
  # Environment variables
  medusa_backend_url          = var.medusa_backend_url
  next_public_base_url        = var.next_public_base_url
  next_public_default_region  = var.next_public_default_region
  
  # Database connection
  db_host     = module.cloud_sql.db_host
  db_name     = var.db_name
  db_user     = var.db_user
  db_password = var.db_password
  
  # Secret references
  medusa_publishable_key_secret = google_secret_manager_secret.medusa_publishable_key.secret_id
  stripe_key_secret            = var.stripe_public_key != "" ? google_secret_manager_secret.stripe_key[0].secret_id : ""
  
  labels = local.common_labels
  
  depends_on = [
    google_project_service.required_apis,
    module.cloud_sql,
    google_secret_manager_secret_version.medusa_publishable_key
  ]
}