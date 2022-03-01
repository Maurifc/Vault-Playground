## Tasks
- Deploy TF - 1 cluster minimo k8s projeto ptm-devops - idealmente cluster privado no futuro, possivel tb authorized master ips
- Helm install vault (values em repo próprio?)
- Prod config usando sh script ou ?
- Deploy inject no cluster thorus ptm-hml
- sensors-mssql - acessa sql server vm
  - usar um backend para sql server?
  - usar kv?

> Visão um pouco mais clara das features que nós poderíamos tirar proveito no vault

## Next steps
- Firewall: Allow Port 8200 only to client clusters
- Config SQL Server as Secret Engine

------
## Setup Vault Server
### Requirements
- Kubernetes cluster
- GCP Bucket (for Vault storage backend)
- GCP Key ring (for auto unsealing)
- GCP Service Account (Bucket Admin and cryptoKeyEncrypterDecrypter)
- GCP Service Account Key (json file)
- Static external IP
- Kubectl working with your cluster

### Setup
Configure .env file
```bash
cp .env.sample .env
nano .env
```

Set these variables
```
export VAULT_HOST=<STATIC IP HERE>
export GCP_PROJECT=<GCP PROJECT ID>
export GCS_BUCKET_NAME=<GCS BUCKET NAME>
export VAULT_SA_NAME=<GCP SERVICE ACCOUNT NAME>
...
export CONTEXT_VAULT_CLUSTER=<KUBECTL CONTEXT (VAULT SERVER)>
```

Source the .env file
```bash
source .env
```

Create a service account key and save it to vault_server_setup folder
```bash
gcloud iam service-accounts keys create \
      --iam-account $VAULT_SA vault_server_setup/vault_gcp_key.json
```

> Ensure the key file's name is: vault_gcp_key.json

Run setup  
```
cd vault_server_setup
./vault_server_setup.sh
```

> Save tmp/vault-init in a safe place

Set VAULT_TOKEN variable (get the token from tmp/vault-init)
```bash
cd ..
nano .env

# Vault Access token 
export VAULT_TOKEN=YOUR TOKEN HERE
```

Source .env to load Vault Root token
```
source .env
```

Add CA certificate as trusted
```
sudo cp tmp/vault.ca /usr/local/share/ca-certificates/vault.crt
sudo update-ca-certificates
```

Check Vault server status
```bash
$ vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    5
Threshold                3
Version                  1.9.2
Storage Type             gcs
Cluster Name             vault-cluster-2a5575ec
Cluster ID               8c152c50-7264-04e3-b330-e03b97ff68d0
HA Enabled               true
HA Cluster               https://vault-1.vault-internal:8201
HA Mode                  standby
Active Node Address      https://10.10.10.100:8200

```

## Setup Injector
### Requirements:
- Kubernetes Cluster for Client
- Kubectl working with your cluster
- vault.ca file


Set these variables at .env file
```
# Vault Server IP Address (Check Terraform output)
export VAULT_HOST=STATIC IP HERE
...
# Cluster that will consume secrets from Vault
export CONTEXT_CLIENT_CLUSTER=KUBECTL CONTEXT (CLIENT CLUSTER)
```

**Put vault.ca file (from the Vaul Server cluster) on injector_setup dir**  
If you just installed Vaul Server, copy vault.ca file from vault_server_setup/tmp
```bash
cp vault_server_setup/tmp/vault.ca injector_setup/
```

Install Vault Injector
```bash
cd injector_setup
./injector_setup.sh
```

## Setup Kubernetes Authentication Method on Vault
### Requirements:
- Vault credentials
- Kubectl working with your client cluster


Set these variables at .env file
```
# Vault Server IP Address (Check Terraform output)
export VAULT_HOST=<STATIC IP HERE>

# Vault Access token
export VAULT_TOKEN=<YOUR TOKEN HERE>
...
# Cluster that will consume secrets from Vault
export CONTEXT_CLIENT_CLUSTER=<KUBECTL CONTEXT - CLIENT CLUSTER>
```

Enable Kubernetes Authentication Method
```bash
cd auth_method_setup
./auth_method_setup.sh
```

## Insert Secrets, Policy and Role
### Requirements:
- Vault credentials

// TODO: Add instructions to setup .env with app and env info
Set these variables at .env file
```
# Vault Server IP Address (Check Terraform output)
export VAULT_HOST=<STATIC IP HERE>

# Vault Access token
export VAULT_TOKEN=<YOUR TOKEN HERE>
export APP_NAME=mailapi
export SECRET_CONTAINER=config
export SERVICE_ACCOUNT=$APP_NAME-sa
export SERVICE_ACCOUNT_NAMESPACE=development
export ENVIRONMENT=thorus
export APP_NAMESPACE=development
```

Enter secret_setup directory
```
cd secret_setup
```

Create a secret.json file from secret.json.sample
```
cp secret.json.sample secret.json
```


Edit secret.json according your needs
```
{
    "DB_PASS": 123456,
    "API_TOKEN": "ABCDEFG"    
}
```
Put the secret on Vault server
```bash
./secret_setup.sh
```

