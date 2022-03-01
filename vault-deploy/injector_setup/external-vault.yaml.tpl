# This allows vault injector to reference external vault as a dns
apiVersion: v1
kind: Service
metadata:
  name: external-vault
spec:
  ports:
    - protocol: TCP
      port: 8200
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-vault
subsets:
  - addresses:
      - ip: $EXTERNAL_VAULT_ADDR
    ports:
      - port: 8200