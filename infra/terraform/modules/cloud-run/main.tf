# Cloud Build trigger for automatic deployments
resource "google_cloudbuild_trigger" "app_trigger" {
  name        = "${var.app_name}-${var.environment}-trigger-${var.name_suffix}"
  description = "Build and deploy ${var.app_name} on commit"

  github {
    owner = "YOUR_GITHUB_USERNAME"  # Update this
    name  = "YOUR_REPO_NAME"        # Update this
    push {
      branch = var.environment == "production" ? "main" : var.environment
    }
  }

  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [
        "build",
        "-t", "gcr.io/$PROJECT_ID/${var.app_name}:$COMMIT_SHA",
        "-t", "gcr.io/$PROJECT_ID/${var.app_name}:latest",
        "."
      ]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "gcr.io/$PROJECT_ID/${var.app_name}:$COMMIT_SHA"]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "gcr.io/$PROJECT_ID/${var.app_name}:latest"]
    }

    step {
      name = "gcr.io/cloud-builders/gcloud"
      args = [
        "run", "deploy", google_cloud_run_service.app.name,
        "--image", "gcr.io/$PROJECT_ID/${var.app_name}:$COMMIT_SHA",
        "--region", var.region,
        "--platform", "managed"
      ]
    }
  }
}

# Cloud Run service
resource "google_cloud_run_service" "app" {
  name     = "${var.app_name}-${var.environment}-${var.name_suffix}"
  location = var.region

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = tostring(var.max_scale)
        "autoscaling.knative.dev/minScale"        = tostring(var.min_scale)
        "run.googleapis.com/cpu-throttling"       = "false"
        "run.googleapis.com/execution-environment" = "gen2"
      }
      
      labels = var.labels
    }

    spec {
      container_concurrency = 80
      timeout_seconds      = 300

      containers {
        image = "gcr.io/${var.project_id}/${var.app_name}:latest"
        
        ports {
          name           = "http1"
          container_port = 8000
        }

        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }

        # Environment variables
        env {
          name  = "NODE_ENV"
          value = var.environment == "production" ? "production" : "development"
        }

        env {
          name  = "PORT"
          value = "8000"
        }

        env {
          name  = "MEDUSA_BACKEND_URL"
          value = var.medusa_backend_url
        }

        env {
          name  = "NEXT_PUBLIC_BASE_URL"
          value = var.next_public_base_url
        }

        env {
          name  = "NEXT_PUBLIC_DEFAULT_REGION"
          value = var.next_public_default_region
        }

        # Database connection
        env {
          name  = "DATABASE_URL"
          value = "postgresql://${var.db_user}:${var.db_password}@${var.db_host}:5432/${var.db_name}?sslmode=require"
        }

        # Secret environment variables
        env {
          name = "NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY"
          value_from {
            secret_key_ref {
              name = var.medusa_publishable_key_secret
              key  = "latest"
            }
          }
        }

        dynamic "env" {
          for_each = var.stripe_key_secret != "" ? [1] : []
          content {
            name = "NEXT_PUBLIC_STRIPE_KEY"
            value_from {
              secret_key_ref {
                name = var.stripe_key_secret
                key  = "latest"
              }
            }
          }
        }

        # Health check
        liveness_probe {
          http_get {
            path = "/api/health"
            port = 8000
          }
          initial_delay_seconds = 30
          period_seconds        = 10
          timeout_seconds       = 5
          failure_threshold     = 3
        }

        startup_probe {
          http_get {
            path = "/api/health"
            port = 8000
          }
          initial_delay_seconds = 0
          period_seconds        = 10
          timeout_seconds       = 5
          failure_threshold     = 30
        }
      }

      service_account_name = google_service_account.cloud_run_sa.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_iam_member.cloud_run_sa_roles
  ]
}

# Service account for Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.app_name}-${var.environment}-sa-${substr(var.name_suffix, 0, 8)}"
  display_name = "Cloud Run service account for ${var.app_name}"
  description  = "Service account for ${var.app_name} Cloud Run service"
}

# IAM roles for the service account
resource "google_project_iam_member" "cloud_run_sa_roles" {
  for_each = toset([
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
    "roles/storage.objectViewer",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Allow public access to Cloud Run service
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.app.name
  location = google_cloud_run_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Domain mapping (optional)
resource "google_cloud_run_domain_mapping" "domain" {
  count = var.custom_domain != "" ? 1 : 0
  
  location = var.region
  name     = var.custom_domain

  metadata {
    namespace = var.project_id
    labels    = var.labels
  }

  spec {
    route_name = google_cloud_run_service.app.name
  }
}