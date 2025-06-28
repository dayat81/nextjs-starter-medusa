# Cloud Storage bucket for static assets
resource "google_storage_bucket" "assets" {
  name          = "${var.project_id}-${var.environment}-assets-${var.name_suffix}"
  location      = var.storage_location
  force_destroy = var.environment != "production"

  # Versioning
  versioning {
    enabled = var.environment == "production"
  }

  # Lifecycle management
  lifecycle_rule {
    condition {
      age = var.environment == "production" ? 365 : 30
    }
    action {
      type = "Delete"
    }
  }

  # Enable uniform bucket-level access
  uniform_bucket_level_access = true

  # CORS configuration for web access
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  # Labels
  labels = var.labels
}

# Make bucket publicly readable for static assets
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backup bucket for database backups
resource "google_storage_bucket" "backups" {
  name          = "${var.project_id}-${var.environment}-backups-${var.name_suffix}"
  location      = var.storage_location
  force_destroy = var.environment != "production"

  # Versioning for backups
  versioning {
    enabled = true
  }

  # Lifecycle management for backups
  lifecycle_rule {
    condition {
      age = var.environment == "production" ? 90 : 30
    }
    action {
      type = "Delete"
    }
  }

  # Archive old backups
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Labels
  labels = var.labels
}

# Cloud CDN for global distribution
resource "google_compute_backend_bucket" "cdn_backend" {
  name        = "${var.environment}-cdn-backend-${var.name_suffix}"
  bucket_name = google_storage_bucket.assets.name
  description = "CDN backend for static assets"
  enable_cdn  = true
}

# URL map for CDN
resource "google_compute_url_map" "cdn_url_map" {
  name            = "${var.environment}-cdn-url-map-${var.name_suffix}"
  default_service = google_compute_backend_bucket.cdn_backend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.cdn_backend.id
    
    path_rule {
      paths   = ["/assets/*", "/images/*", "/static/*"]
      service = google_compute_backend_bucket.cdn_backend.id
    }
  }
}

# Global forwarding rule for CDN
resource "google_compute_global_forwarding_rule" "cdn_forwarding_rule" {
  name       = "${var.environment}-cdn-forwarding-rule-${var.name_suffix}"
  target     = google_compute_target_http_proxy.cdn_proxy.id
  port_range = "80"
}

# HTTP proxy for CDN
resource "google_compute_target_http_proxy" "cdn_proxy" {
  name    = "${var.environment}-cdn-proxy-${var.name_suffix}"
  url_map = google_compute_url_map.cdn_url_map.id
}