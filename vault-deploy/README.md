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
Configure .env file
```
nano .env
```


Run Vault server setup  
```
./vault_server_setup.sh
```


Unseal Vault manually
```
kubectl exec vault-0 -n vault -- vault operator unseal #KEY 1
kubectl exec vault-0 -n vault -- vault operator unseal #KEY 2
kubectl exec vault-0 -n vault -- vault operator unseal #KEY 3
```

Add CA certificate as trusted
```
sudo cp ${TMPDIR}/vault.ca /usr/local/share/ca-certificates/vault.crt
sudo update-ca-certificates
```

Add Vault to your hosts file and redirect port to Vault server
```
sudo echo -n "127.0.0.1       vault-server-tls" > /etc/hosts
kubectl port-forward svc/vault -n vault 8200:8200
```

Export variables to access Vault
```
export VAULT_ADDR='https://vault-server-tls:8200'
export VAULT_TOKEN=s.JZmF6XFaDDNSSA8B8FeyFiHX
```

Check vault status
```
vault status
```

## Setup Auth Method
TODO

## Insert Secrets, Policy and Role
TODO

