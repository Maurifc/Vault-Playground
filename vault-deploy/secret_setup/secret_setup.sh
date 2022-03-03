#!/bin/bash

# Check if .env exists
printf "Sourcing envs from .env file\n";
if [ -f ../.env ];
then
    source ../.env;
else
    printf "Error: .env file not found\n";
    exit 1;
fi


if [ ! -f secret.json ];
then
    printf "Error: secret.json file not found\n";
    exit 1;
fi

# Check if kv is enabled on path secret/
kvEnabled=$(vault secrets list | grep $ENVIRONMENT/ | wc -l)

printf "\nEnabling kv secrets v2\n";
if [ $kvEnabled = '1' ];
then
    printf 'kv already enabled on secrets/\n'
else
    vault secrets enable -version=2 -path=$ENVIRONMENT/ kv
fi;

printf "\nCreating secrets from file %s\n" $SECRET_FILE;
vault kv put $ENVIRONMENT/$APP_NAMESPACE/$APP_NAME/$SECRET_CONTAINER @$SECRET_FILE

#
printf "\nCreating policies\n";
vault policy write $APP_NAME-$APP_NAMESPACE - <<EOF
path "$ENVIRONMENT/data/$APP_NAMESPACE/$APP_NAME/$SECRET_CONTAINER" {
capabilities = ["read"]
}
EOF

#
printf "\nCreating kubenetes access role\n";
vault write auth/$ENVIRONMENT/role/$APP_NAME-$APP_NAMESPACE \
        bound_service_account_names=$APP_NAME-sa \
        bound_service_account_namespaces=$SERVICE_ACCOUNT_NAMESPACE \
        policies=$APP_NAME-$APP_NAMESPACE \
        ttl=24h