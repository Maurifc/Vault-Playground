variable "gke_cluster_name" {
  default     = "vaulter"
}
variable "gke_num_nodes" {
  default     = 2
}

# Provider
variable "project_id" {
}

variable "credentials_file" {
}

variable "region" {
  default = "southamerica-east1"
}
variable "zone" {
  default = "southamerica-east1-a"
}