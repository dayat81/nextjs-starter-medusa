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

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "enable_vpc" {
  description = "Enable VPC network"
  type        = bool
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}