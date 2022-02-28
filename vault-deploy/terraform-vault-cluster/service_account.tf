resource "google_service_account" "default" {
  account_id   = "vault-hosts"
  display_name = "Service Account"
}

resource "google_service_account" "vault_sa" {
  account_id   = "vault-sa"
  display_name = "Vault Service Account"
}