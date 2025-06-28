# VPC Network
resource "google_compute_network" "vpc" {
  count = var.enable_vpc ? 1 : 0
  
  name                    = "${var.environment}-vpc-${var.name_suffix}"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
  
  depends_on = [var.labels]
}

# Subnet for Cloud Run and other services
resource "google_compute_subnetwork" "subnet" {
  count = var.enable_vpc ? 1 : 0
  
  name          = "${var.environment}-subnet-${var.name_suffix}"
  ip_cidr_range = var.vpc_cidr
  region        = var.region
  network       = google_compute_network.vpc[0].id
  
  # Enable private Google access for Cloud SQL
  private_ip_google_access = true
}

# Private service connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  count = var.enable_vpc ? 1 : 0
  
  name          = "${var.environment}-private-ip-${var.name_suffix}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc[0].id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.enable_vpc ? 1 : 0
  
  network                 = google_compute_network.vpc[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

# Cloud NAT for outbound internet access
resource "google_compute_router" "router" {
  count = var.enable_vpc ? 1 : 0
  
  name    = "${var.environment}-router-${var.name_suffix}"
  region  = var.region
  network = google_compute_network.vpc[0].id
}

resource "google_compute_router_nat" "nat" {
  count = var.enable_vpc ? 1 : 0
  
  name                               = "${var.environment}-nat-${var.name_suffix}"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  count = var.enable_vpc ? 1 : 0
  
  name    = "${var.environment}-allow-internal-${var.name_suffix}"
  network = google_compute_network.vpc[0].name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
}

resource "google_compute_firewall" "allow_http_https" {
  count = var.enable_vpc ? 1 : 0
  
  name    = "${var.environment}-allow-http-https-${var.name_suffix}"
  network = google_compute_network.vpc[0].name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8000", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}