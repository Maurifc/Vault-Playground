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

printf "\nUninstalling Vaul release (HELM)\n"
helm uninstall vault -n vault

printf "\nRemoving remaining resources from cluster\n"
kubectl delete secrets vault-server-tls -n vault
kubectl delete csr vault-csr
kubectl delete ns vault