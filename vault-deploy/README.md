## Tasks
- Deploy TF - 1 cluster minimo k8s projeto ptm-devops - idealmente cluster privado no futuro, possivel tb authorized master ips
- Helm install vault (values em repo próprio?)
- Prod config usando sh script ou ?
- Deploy inject no cluster thorus ptm-hml
- sensors-mssql - acessa sql server vm
  - usar um backend para sql server?
  - usar kv?

> Visão um pouco mais clara das features que nós poderíamos tirar proveito no vault

## First Steps
- Install Vault Server (with TLS) with Helm*
- Install Vault Injector
- Setup Vault Server: *
  - Config Kubernetes Auth
  - Create secrets
  - Create role
  - Create policy
  - Create shell script
- Terraform Cluster GKE  

## Next steps
- Config SQL Server as Secret Engine
- Install Vault Server with HA (GCS)

------
## Setup Vault Server
### Requirements
- Kubernetes cluster
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
export VAULT_HOST=STATIC IP HERE
...
export CONTEXT_VAULT_CLUSTER=KUBECTL CONTEXT (VAULT SERVER)
```


Run Vault server setup  
```
cd vault_server_setup
./vault_server_setup.sh
```

> Save tmp/vault-init in a safe place


Unseal Vault manually (get the keys from tmp/vault-init)
```
kubectl exec vault-0 -n vault -- vault operator unseal #KEY 1
kubectl exec vault-0 -n vault -- vault operator unseal #KEY 2
kubectl exec vault-0 -n vault -- vault operator unseal #KEY 3
```

Set VAULT_TOKEN variable (get the token from tmp/vault-init)
```bash
cd ..
nano .env
```

```bash
# Vault Access token 
export VAULT_TOKEN=YOUR TOKEN HERE
```

Add CA certificate as trusted
```
sudo cp tmp/vault.ca /usr/local/share/ca-certificates/vault.crt
sudo update-ca-certificates
```

Source .env to load Vault Root token
```
source .env
```

Check server vault status
```
vault status
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

Set these variables at .env file
```
# Vault Server IP Address (Check Terraform output)
export VAULT_HOST=<STATIC IP HERE>

# Vault Access token
export VAULT_TOKEN=<YOUR TOKEN HERE>
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

