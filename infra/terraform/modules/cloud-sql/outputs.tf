output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.connection_name
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
  sensitive   = true
}

output "db_host" {
  description = "Database host (private IP)"
  value       = google_sql_database_instance.postgres.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Name of the database"
  value       = google_sql_database.database.name
}

output "database_user" {
  description = "Database user name"
  value       = google_sql_user.user.name
}

output "ssl_cert" {
  description = "SSL certificate for secure connections"
  value       = google_sql_ssl_cert.client_cert
  sensitive   = true
}