#!/bin/bash

printf "WARNING !!!\n"
printf "This will remove Vault server completely from your cluster!\n\n"
printf "Are you sure you want to uninstall Vault server? (yes / no): "
read answer

if [[ $answer != "yes" ]];
then
    printf "Exiting...\n";
    exit 0;
fi

printf "Sourcing envs from .env file\n";
# Check if .env exists
if [ -f ../.env ];
then
    source ../.env;
else
    printf "Error: .env file not found\n";
    exit 1;
fi

printf "\nChanging context to ${CONTEXT_VAULT_CLUSTER}\n";
kubectl config use-context $CONTEXT_VAULT_CLUSTER

if [ $? != 0 ];
then
    printf "Aborting: Can't change context to %s\n" $CONTEXT_VAULT_CLUSTER;
    exit 1;
fi

printf "\nUninstalling Vaul release (HELM)\n"
helm uninstall vault -n vault

printf "\nRemoving remaining resources from cluster\n"
kubectl delete secrets vault-server-tls -n vault
kubectl delete csr vault-csr
kubectl delete ns vault

printf "\nDelete your bucket content manually\n"