output "cluster_name" {
  value = google_container_cluster.autopilot.name
}

output "cluster_location" {
  value = google_container_cluster.autopilot.location
}

output "bucket_name" {
  value = google_storage_bucket.tici.name
}

output "service_account_email" {
  value = google_service_account.tici.email
}

output "hmac_access_id" {
  value = google_storage_hmac_key.tici.access_id
}

output "hmac_secret" {
  value     = google_storage_hmac_key.tici.secret
  sensitive = true
}
