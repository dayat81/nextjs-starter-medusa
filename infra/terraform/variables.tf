variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "nextjs-storefront"
}

# Application Configuration
variable "medusa_backend_url" {
  description = "Medusa backend URL"
  type        = string
}

variable "next_public_base_url" {
  description = "Next.js base URL"
  type        = string
}

variable "next_public_default_region" {
  description = "Default region for the storefront"
  type        = string
  default     = "us"
}

variable "medusa_publishable_key" {
  description = "Medusa publishable API key"
  type        = string
  sensitive   = true
}

variable "stripe_public_key" {
  description = "Stripe public key"
  type        = string
  sensitive   = true
  default     = ""
}

# Database Configuration
variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "medusa"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "medusa"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Cloud Run Configuration
variable "cloud_run_cpu" {
  description = "CPU allocation for Cloud Run"
  type        = string
  default     = "1000m"
}

variable "cloud_run_memory" {
  description = "Memory allocation for Cloud Run"
  type        = string
  default     = "2Gi"
}

variable "cloud_run_max_scale" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 100
}

variable "cloud_run_min_scale" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 0
}

# Storage Configuration
variable "storage_location" {
  description = "Cloud Storage bucket location"
  type        = string
  default     = "US"
}

# Networking
variable "enable_vpc" {
  description = "Enable VPC network"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}