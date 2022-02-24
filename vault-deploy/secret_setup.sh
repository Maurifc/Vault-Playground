#!/bin/bash

# Check if .env exists
printf "Sourcing envs from .env file\n";
if [ -f .env ];
then
    source .env;
else
    printf "Error: .env file not found\n";
    exit 1;
fi

#
printf "\nEnabling kv secrets v2\n";
vault secrets enable -version=2 kv

#
printf "\nCreating secrets from file %s\n" $SECRET_FILE;
vault kv put secret/$APP_NAME/$SECRET_CONTAINER @$SECRET_FILE

#
printf "\nCreating policies\n";
vault policy write $APP_NAME - <<EOF
path "secret/data/$APP_NAME/$SECRET_CONTAINER" {
capabilities = ["read"]
}
EOF

#
printf "\nCreating kubenetes access role\n";
vault write auth/kubernetes/role/$APP_NAME \
        bound_service_account_names=$APP_NAME-sa \
        bound_service_account_namespaces=$SERVICE_ACCOUNT_NAMESPACE \
        policies=$APP_NAME \
        ttl=24h