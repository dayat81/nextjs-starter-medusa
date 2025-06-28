# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "postgres" {
  name             = "${var.environment}-postgres-${var.name_suffix}"
  database_version = "POSTGRES_15"
  region           = var.region
  
  deletion_protection = var.environment == "production" ? true : false

  settings {
    tier = var.db_tier
    
    # Availability and backup
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = var.environment == "production" ? 30 : 7
      }
    }

    # Networking
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_network != null ? var.vpc_network.id : null
      enable_private_path_for_google_cloud_services = true
    }

    # Disk configuration
    disk_type    = "PD_SSD"
    disk_size    = var.environment == "production" ? 100 : 20
    disk_autoresize = true
    
    # Database flags for performance
    database_flags {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    }
    
    database_flags {
      name  = "log_statement"
      value = "all"
    }

    # Maintenance window
    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    # Insights and monitoring
    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
  }

  # Labels
  dynamic "settings" {
    for_each = [var.labels]
    content {
      user_labels = settings.value
    }
  }
}

# Database
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

# Database user
resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}

# SSL Certificate for secure connections
resource "google_sql_ssl_cert" "client_cert" {
  common_name = "${var.environment}-client-cert"
  instance    = google_sql_database_instance.postgres.name
}