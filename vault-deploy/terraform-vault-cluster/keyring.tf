resource "google_kms_key_ring" "keyring" {
  name     = var.vault_keyring_name
  location = "global"
}

resource "google_kms_crypto_key" "vault-unseal-key" {
  name            = "vault-unseal-key"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "100000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_binding" "key_iam" {
  crypto_key_id = google_kms_crypto_key.vault-unseal-key.id
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"  

  members = [
      "serviceAccount:${google_service_account.vault_sa.email}"
  ]
}