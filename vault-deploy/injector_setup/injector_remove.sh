#!/bin/bash

printf "Sourcing envs from .env file\n";
if [ -f ../.env ];
then
    source ../.env;
else
    printf "Error: .env file not found\n";
    exit 1;
fi

printf "\nChanging context to ${CONTEXT_CLIENT_CLUSTER}\n";
kubectl config use-context $CONTEXT_CLIENT_CLUSTER

if [ $? != 0 ];
then
    printf "Aborting: Can't change context to %s\n" $CONTEXT_CLIENT_CLUSTER;
    exit 1;
fi

printf "\nRemoving Service and Endpoint for injector\n";
kubectl delete service external-vault \
    --namespace ${NAMESPACE} \

printf "\nUninstalling Vault injector chart\n"
helm uninstall vault

printf "\nRemoving namespace\n"
kubectl delete namespace ${NAMESPACE}