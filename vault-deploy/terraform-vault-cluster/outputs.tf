output "vault_bucket" {
  value       = google_storage_bucket.vault-data.name
  description = "Vault Bucket"
}

output "vault_service_account" {
  value       = google_service_account.vault_sa.account_id
  description = "GCP Vault Service Account"
}

output "vault_keyring_name" {
  value       = google_kms_key_ring.keyring.name
  description = "GCP Vault Keyring"
}

output "vault_key_name" {
  value       = google_kms_crypto_key.vault-unseal-key.name
  description = "GCP Vault Key"
}
output "region" {
  value       = var.region
  description = "Region"
}
output "zone" {
  value       = var.zone
  description = "Zone"
}

output "project_id" {
  value       = var.project_id
  description = "Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "vault_external_ip" {
  value = google_compute_address.vault_ip.address
  description = "Vault External IP"
}