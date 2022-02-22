## Start Vault VM
To perform this action, you need Vagrant and Virtualbox properly installed
```bash
vagrant up
```

## SSH into the VM
```bash
vagrant ssh
```
## Start Vault Server on dev mode
Close this terminal cause the server to stop
```bash
vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200
```

## Pause VM when not using it
From another terminal, but in the vault-vm folder...
```bash
vagrant suspend
```