#!/bin/bash

printf "Sourcing envs from .env file\n";
# Check if .env exists
if [ -f ../.env ];
then
    source ../.env;
else
    printf "Error: .env file not found\n";
    exit 1;
fi

printf "\nEnabling Vault Kubernetes Auth Method\n";
vault auth disable $ENVIRONMENT
