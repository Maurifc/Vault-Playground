variable "gke_cluster_name" {
  default     = "vaulter"
}
variable "gke_num_nodes" {
  default     = 2
}

variable "vault_keyring_name" {
  default     = "vault-unseal-kr"
}

variable "region" {
  default = "southamerica-east1"
}
variable "zone" {
  default = "southamerica-east1-a"
}

# Set at .tfvars file
variable "project_id" {
}

variable "credentials_file" {
}