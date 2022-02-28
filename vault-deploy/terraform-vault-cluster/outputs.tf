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