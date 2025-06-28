variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for resource names"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "cpu" {
  description = "CPU allocation for Cloud Run"
  type        = string
}

variable "memory" {
  description = "Memory allocation for Cloud Run"
  type        = string
}

variable "max_scale" {
  description = "Maximum number of Cloud Run instances"
  type        = number
}

variable "min_scale" {
  description = "Minimum number of Cloud Run instances"
  type        = number
}

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
}

variable "db_host" {
  description = "Database host"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database user"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "medusa_publishable_key_secret" {
  description = "Secret Manager secret name for Medusa publishable key"
  type        = string
}

variable "stripe_key_secret" {
  description = "Secret Manager secret name for Stripe key"
  type        = string
  default     = ""
}

variable "custom_domain" {
  description = "Custom domain for the application"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}