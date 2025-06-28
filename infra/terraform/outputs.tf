output "cloud_run_url" {
  description = "URL of the deployed Cloud Run service"
  value       = module.cloud_run.service_url
}

output "cloud_run_service_name" {
  description = "Name of the Cloud Run service"
  value       = module.cloud_run.service_name
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = module.cloud_sql.connection_name
}

output "database_private_ip" {
  description = "Private IP of the Cloud SQL instance"
  value       = module.cloud_sql.private_ip_address
  sensitive   = true
}

output "storage_bucket_name" {
  description = "Name of the Cloud Storage bucket for assets"
  value       = module.storage.bucket_name
}

output "storage_bucket_url" {
  description = "URL of the Cloud Storage bucket"
  value       = module.storage.bucket_url
}

output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = module.networking.vpc_name
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}