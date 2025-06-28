output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_service.app.name
}

output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_service.app.status[0].url
}

output "service_account_email" {
  description = "Email of the Cloud Run service account"
  value       = google_service_account.cloud_run_sa.email
}

output "domain_mapping_status" {
  description = "Status of domain mapping"
  value       = var.custom_domain != "" ? google_cloud_run_domain_mapping.domain[0].status : null
}