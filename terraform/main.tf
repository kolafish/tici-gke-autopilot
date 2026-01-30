provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "google_storage_bucket" "tici" {
  name                        = "tici-${random_id.suffix.hex}"
  location                    = var.bucket_location
  force_destroy               = true
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.apis]
}

resource "google_service_account" "tici" {
  account_id   = "tici-${random_id.suffix.hex}"
  display_name = "tici-gcs"
  depends_on   = [google_project_service.apis]
}

resource "google_storage_bucket_iam_member" "tici_object_admin" {
  bucket = google_storage_bucket.tici.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tici.email}"
}

resource "google_storage_hmac_key" "tici" {
  service_account_email = google_service_account.tici.email
  depends_on            = [google_project_service.apis]
}

resource "google_container_cluster" "autopilot" {
  name               = var.cluster_name
  location           = var.region
  enable_autopilot   = true
  deletion_protection = false

  network    = var.network
  subnetwork = var.subnetwork

  ip_allocation_policy {}

  release_channel {
    channel = "REGULAR"
  }

  depends_on = [google_project_service.apis]
}
