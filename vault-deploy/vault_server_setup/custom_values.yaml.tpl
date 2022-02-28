global:
  enabled: true
  tlsDisable: false

injector:
  enabled: false

server:
  ha:
    enabled: true
    replicas: 3

    config: |
      ui = false

      listener "tcp" {
        tls_disable = 0
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
        tls_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
        tls_client_ca_file = "/vault/userconfig/vault-server-tls/vault.ca"
      }

      storage "gcs" {
        bucket     = "$GCS_BUCKET_NAME"
        ha_enabled = "true"
      }
      service_registration "kubernetes" {}

      seal "gcpckms" {
        project     = "$GCP_PROJECT"
        region      = "global"
        key_ring    = "vault-helm-unseal-kr"
        crypto_key  = "vault-helm-unseal-key"
      }

  extraEnvironmentVars:
    VAULT_CACERT: /vault/userconfig/vault-server-tls/vault.ca
    GOOGLE_APPLICATION_CREDENTIALS: /vault/userconfig/vault-gcs/vault_gcs_key.json

  extraVolumes:
    - type: secret
      name: vault-server-tls # Matches the ${SECRET_NAME} from above

  volumes:
  - name: vault-gcs
    secret:
      secretName: vault-gcs

  volumeMounts:
    - mountPath: "/vault/userconfig/vault-gcs"
      name: vault-gcs
      readOnly: true

  standalone:
    enabled: false
    config: |
      listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
        tls_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
        tls_client_ca_file = "/vault/userconfig/vault-server-tls/vault.ca"
      }

      storage "file" {
        path = "/vault/data"
      }

  service:
    type: LoadBalancer