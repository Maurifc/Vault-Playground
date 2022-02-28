resource "google_service_account" "default" {
  account_id   = "vault-hosts"
  display_name = "Service Account"
}