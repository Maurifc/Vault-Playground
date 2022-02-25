kind: Secret
apiVersion: v1
metadata:
  name: vault-tls-secret
stringData:
  ca-bundle.crt: |
    $CA
type: Opaque