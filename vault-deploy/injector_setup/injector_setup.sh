#!/bin/bash

printf "Sourcing envs from .env file\n";
if [ -f ../.env ];
then
    source ../.env;
else
    printf "Error: .env file not found\n";
    exit 1;
fi

if [ ! -f vault.ca ];
then
    printf "Error: vault.ca file not found\n";
    exit 1;
fi

printf "\nChanging context to ${CONTEXT_CLIENT_CLUSTER}\n";
kubectl config use-context $CONTEXT_CLIENT_CLUSTER

if [ $? != 0 ];
then
    printf "Aborting: Can't change context to %s\n" $CONTEXT_CLIENT_CLUSTER;
    exit 1;
fi

#
if [[ $TLS_ENABLED = true ]];
then
    printf "\nInstalling vault Injector: TLS Enabled\n";
    EXTERNAL_URL="https://external-vault.${NAMESPACE}.svc.cluster.local:8200/"
else
    printf "\nInstalling vault Injector: TLS Disable\nd"
    EXTERNAL_URL="http://external-vault.${NAMESPACE}.svc.cluster.local:8200/"
fi

printf "\nCreating namespace\n"
kubectl create namespace ${NAMESPACE}

printf "\nInstalling Vault injector\n"
helm install vault hashicorp/vault \
    --namespace ${NAMESPACE} \
    --set "injector.externalVaultAddr=${EXTERNAL_URL}" --version 0.19.0

#
printf "\nCreating Service and Endpoint for injector\n";
envsubst < external-vault.yaml.tpl > ${TMPDIR}/external-vault.yaml
kubectl apply -f tmp/external-vault.yaml \
    --namespace ${NAMESPACE} \