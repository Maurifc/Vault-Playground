#!/bin/bash

DATABASE_NAME=""
DATABASE_HOST=""
PASSWORD=""
USER_NAME=""
PROJECT=""
INSTANCE=""

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
   [ ! -n "$DATABASE_HOST" ] ||
   [ ! -n "$PASSWORD" ] ||
   [ ! -n "$USER_NAME" ] ||
   [ ! -n "$PROJECT" ] ||
   [ ! -n "$INSTANCE" ]
then
    echo -n "GCP Project: "
    read PROJECT
    
    echo -n "Instance: "
    read INSTANCE

    echo -n "Enter Database name: "
    read DATABASE_NAME

    echo -n "Enter Database host (IP or dns): "
    read DATABASE_HOST

    echo -n "Enter user name to connect to database: "
    read USER_NAME

    echo -n "Enter user password to connect to database: "
    read PASSWORD

    clear
else
    printf "Variables loaded from .env file:\n\n";
fi

echo "Vault Server: "$VAULT_ADDR
echo "GCP Project: "$PROJECT
echo "DB Instance: "$INSTANCE
echo "Database Name: "$DATABASE_NAME
echo "Database Host: "$DATABASE_HOST
echo "Database User: "$USER_NAME
echo "Database Pass: ********"

printf "\nAre you sure you want to procceed? (yes / no): "
read ANSWER

if [ "$ANSWER" != "yes" ] && [ "$ANSWER" != "y" ];
then
    echo "Aborted by user!"
    exit 1;
fi

# Enable the database secrets engine if it is not already enabled:
printf "\nEnabling Vault secret database\n"
vault secrets enable database

# Configure Vault with the proper plugin and connection information:
#              GCP   INTANCE/VM
DATABASE_URI=$PROJECT-$INSTANCE-$DATABASE_NAME

printf "\nWriting database config to Vault\n"
vault write database/config/$DATABASE_URI \
    plugin_name=postgresql-database-plugin \
    allowed_roles=* \
    connection_url="postgresql://{{username}}:{{password}}@${DATABASE_HOST}:5432/${DATABASE_NAME}" \
    username=$USER_NAME \
    password=$PASSWORD