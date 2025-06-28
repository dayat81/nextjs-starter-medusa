output "bucket_name" {
  description = "Name of the assets bucket"
  value       = google_storage_bucket.assets.name
}

output "bucket_url" {
  description = "URL of the assets bucket"
  value       = google_storage_bucket.assets.url
}

output "backup_bucket_name" {
  description = "Name of the backup bucket"
  value       = google_storage_bucket.backups.name
}

output "cdn_ip_address" {
  description = "IP address of the CDN"
  value       = google_compute_global_forwarding_rule.cdn_forwarding_rule.ip_address
}

output "cdn_url" {
  description = "CDN URL for static assets"
  value       = "http://${google_compute_global_forwarding_rule.cdn_forwarding_rule.ip_address}"
}