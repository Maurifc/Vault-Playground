terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.10.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project_id
  region  = var.region
  zone    = var.zone
}

terraform {
  required_version = "~>1.1.6"
  backend "gcs" {
    bucket = "terraform-tlg-states"
    prefix = "ptm-hml/state"
  }
}