variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for the Autopilot cluster"
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name"
}

variable "bucket_location" {
  type        = string
  description = "GCS bucket location"
}

variable "network" {
  type        = string
  description = "VPC network name"
  default     = "default"
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork name"
  default     = "default"
}

variable "manage_apis" {
  type        = bool
  description = "Whether Terraform should enable required GCP APIs"
  default     = true
}
