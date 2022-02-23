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
- Install Vault Server (with TLS) with Helm
- Install Vault Injector
- Setup Vault Server:
  - Create secrets
  - Config Kubernetes Auth
  - Create role
  - Create policy
  - Create shell script
- Terraform Cluster GKE  

## Next steps
- Config SQL Server as Secret Engine
- Install Vault Server with HA (GCS)