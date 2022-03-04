#!/bin/bash

PROJECT=""
INSTANCE=""
DATABASE_NAME=""
ROLE=""
ROLE_FILE=""

# Check if .env exists
if [ -f .env ];
then
    source .env;
else
    printf ".env file not found\n\n";
fi

echo "Checking Vault connectivity..."
vault status > /dev/null

if [ $? != 0 ];
then 
    printf "\nFailed when connecting to Vault server. Check if your Vault CLI is properly setup."
    exit 1;
else
    printf "Vault Server up and running.\n\n"
fi

if [ ! -n "$DATABASE_NAME" ] || 
   [ ! -n "$ROLE" ] ||
   [ ! -n "$ROLE_FILE" ] ||
   [ ! -n "$PROJECT" ] ||
   [ ! -n "$INSTANCE" ]
then
    echo -n "GCP Project: "
    read PROJECT
    
    echo -n "Intance: "
    read INSTANCE
    
    echo -n "Enter role name: "
    read ROLE

    echo -n "Enter SQL file path to create role: "
    read ROLE_FILE

    if [ ! -f $ROLE_FILE ];
    then
        echo "File ${ROLE_FILE} not found";
        echo "Aborting..."
        exit 1;
    fi

    echo -n "Enter Database name: "
    read DATABASE_NAME

    clear
else
    printf "Variables loaded from .env file:\n\n";
fi

echo "GCP Project: "$PROJECT
echo "DB Instance: "$INSTANCE
echo "Vault Server: "$VAULT_ADDR
echo "Database Name: "$DATABASE_NAME
echo "User Role: "$ROLE
echo "Role statement file: "$ROLE_FILE

printf "\nAre you sure you want to procceed? (yes / no): "
read ANSWER

if [ "$ANSWER" != "yes" ] && [ "$ANSWER" != "y" ];
then
    echo "Aborted by user!"
    exit 1;
fi

# Configure Vault with the proper plugin and connection information:
#              GCP   INTANCE/VM
DATABASE_URI=$PROJECT-$INSTANCE-$DATABASE_NAME
ROLE_URI=$DATABASE_URI-$ROLE

printf "\nCreating Vault role\n"
vault write database/roles/$ROLE_URI \
    db_name=$DATABASE_URI \
    creation_statements=@$ROLE_FILE
    default_ttl="1h" \
    max_ttl="24h"

printf "\nYou can create secrets with the following command:"
printf "\nvault read database/creds/${ROLE_URI}\n"