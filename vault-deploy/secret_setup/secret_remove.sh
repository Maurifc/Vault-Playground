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

#
printf "\nDeleting kubenetes access role\n";
vault delete auth/$ENVIRONMENT/role/$APP_NAME-$APP_NAMESPACE

# TODO: Add $ENVIRONMENT in policy name
printf "\nDeleting policies\n";
vault policy delete $APP_NAME-$APP_NAMESPACE

printf "\nDeleting secrets from file %s\n" $SECRET_FILE;
vault kv delete $ENVIRONMENT/$APP_NAMESPACE/$APP_NAME/$SECRET_CONTAINER

# Check if kv is enabled on path secret/
kvEnabled=$(vault secrets list | grep $ENVIRONMENT/ | wc -l)

printf "\nDisabling kv secrets v2\n";
if [ ! $kvEnabled = '1' ];
then
    printf 'kv already disabled on secrets/\n'
else
    vault secrets disable $ENVIRONMENT/
fi;
