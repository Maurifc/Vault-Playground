## Due to this app work, you need:
- Vault up and running (use vault-vm for simplicity)
- Helm installed
- Kubectl installed
- Minikube running

## Follow the steps below to setup your secret, policy and role:

Export Vault IP Address and access token
```bash
export VAULT_ADDR='http://192.168.56.50:8200'
export VAULT_TOKEN="root"
```
Create a key/value secret at secret/data/myapp/config
```bash
vault kv put secret/myapp/config username='giraffe' password='salsa'
```

Enable K8s Auth Method
```bash
vault auth enable kubernetes
```

Export an environment variable with your Vault IP address
```bash
export EXTERNAL_VAULT_ADDR=192.168.56.50
```

Create the external-vault.yaml file from its template
```bash
envsubst < external-vault.yaml.template > external-vault.yaml
```

Apply the Kubernetes manifest
```bash
kubectl apply -f external-vault.yaml
```

Install Vault Injector with Helm
``` bash
helm install vault hashicorp/vault \
    --set "injector.externalVaultAddr=http://external-vault:8200"
```

Wait until Injector pod is ready
```bash
$ kubectl get pods
NAME                                    READY   STATUS    RESTARTS   AGE
vault-agent-injector-649569dfdb-ckx5b   1/1     Running   0               60m
```

Due to configure kubernetes auth method, export those variables...
```bash
VAULT_HELM_SECRET_NAME=$(kubectl get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')

TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)

KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)

KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')
```

...and configure K8s auth on Vault
```bash
vault write auth/kubernetes/config \
        token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
        kubernetes_host="$KUBE_HOST" \
        kubernetes_ca_cert="$KUBE_CA_CERT" \
        issuer="https://kubernetes.default.svc.cluster.local"
```

Create access policy to secret
```bash
vault policy write myapp - <<EOF
path "secret/data/myapp/config" {
capabilities = ["read"]
}
EOF
```

Create a role to allow service account to access the secret
```bash
vault write auth/kubernetes/role/myapp \
        bound_service_account_names=myapp-sa \
        bound_service_account_namespaces=default \
        policies=myapp \
        ttl=24h
```

## Create the myapp deployment and service account

```bash
kubectl apply -f myapp-deploy.yaml
kubectl apply -f serviceaccount.yaml
```

Wait 'till pods initialize and checkout the logs for yours secrets.
(This app prints out the env on console. Don't do this in production)

```bash
kubernetes logs myapp -c myapp
```

### References:
https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault