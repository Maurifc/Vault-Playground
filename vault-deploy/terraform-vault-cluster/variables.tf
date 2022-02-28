variable "gke_cluster_name" {
  default     = "vaulter"
}
variable "gke_num_nodes" {
  default     = 2
}
variable "tf_state_bucket_name" {
  default     = "terraform-tlg-states"
}

variable "tfstate_prefix" {
  default = "ptm-hml/state"
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