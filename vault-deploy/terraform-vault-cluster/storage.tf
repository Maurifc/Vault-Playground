resource "google_storage_bucket" "vault-data" {
  name          = "vault-data-${var.project_id}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
      enabled = true
  }
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.vault-data.name
  role = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.vault_sa.account_id}@${var.project_id}.iam.gserviceaccount.com"
}