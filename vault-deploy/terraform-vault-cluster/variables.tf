# Number of GKE Nodes per zone 
variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes per zone"
}

# Provider
variable "project_id" {
}

variable "credentials_file" {
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-d"
}