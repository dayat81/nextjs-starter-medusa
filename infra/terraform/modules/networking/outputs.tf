output "vpc_network" {
  description = "The VPC network"
  value       = var.enable_vpc ? google_compute_network.vpc[0] : null
}

output "vpc_name" {
  description = "Name of the VPC network"
  value       = var.enable_vpc ? google_compute_network.vpc[0].name : ""
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = var.enable_vpc ? google_compute_subnetwork.subnet[0].name : ""
}

output "private_vpc_connection" {
  description = "Private VPC connection for services"
  value       = var.enable_vpc ? google_service_networking_connection.private_vpc_connection[0] : null
}