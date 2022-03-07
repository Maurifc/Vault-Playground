#!/bin/bash

DATABASE_NAME=""
DATABASE_HOST=""
PASSWORD=""
USER_NAME=""
PROJECT=""
INSTANCE=""

# Enable the database secrets engine if it is not already enabled:
enable_postgres_secret_engine(){
    printf "\nEnabling Vault secret database\n"
    vault secrets enable database
}

# Config access to target database
config_vault_database(){
    printf "\nWriting database config to Vault\n"  
    
    vault write database/config/$DATABASE_URI \
        plugin_name=postgresql-database-plugin \
        allowed_roles=* \
        connection_url="postgresql://{{username}}:{{password}}@${DATABASE_HOST}:5432/${DATABASE_NAME}?sslmode=verify-ca&sslrootcert=/tmp/${SECRET_NAME}/server-ca.pem&sslcert=/tmp/${SECRET_NAME}/client-cert.pem&sslkey=/tmp/${SECRET_NAME}/client-key.pem" \
        username=$USER_NAME \
        password=$PASSWORD
    
}

# Configure Vault with the proper plugin and connection information:
#              GCP   INTANCE/VM
create_roles(){

    for role in ${ROLES[@]}
    do
        printf "\nCreating Database Role: ${role}\n"
        vault write database/roles/$DATABASE_URI-$role \
            db_name=$DATABASE_URI \
            creation_statements=@$role.sql
            default_ttl="1h" \
            max_ttl="24h"
    done
}

# Create Creadentials access policies
create_policies(){
    for role in ${ROLES[@]}
    do
        printf "\nCreating policy: ${role}\n" 
    vault policy write ${DATABASE_URI}-ro - <<EOF
path "database/creds/${DATABASE_URI}-$role" {
capabilities = ["read"]
}
EOF
    done
}

insert_secrets_on_k8s(){
    printf "\nRemoving secret (if exists)\n"
    kubectl delete secret $SECRET_NAME \
        --context $VAULT_CLUSTER_CONTEXT \
        --namespace $VAULT_NAMESPACE \
        
    printf "\nCreating new secret with cert and key files...\n"
    kubectl create secret generic $SECRET_NAME \
        --context $VAULT_CLUSTER_CONTEXT \
        --namespace $VAULT_NAMESPACE \
        --from-file=client-cert.pem=client-cert.pem \
        --from-file=client-key.pem=client-key.pem \
        --from-file=server-ca.pem=server-ca.pem
}

patch_vault_statefulset(){

    printf "\nCreating patch from template file\n"
    envsubst < vault-patch.yaml.tpl > tmp/vault-patch.yaml

    printf "\nApplying Patch\n"
    kubectl patch statefulset vault \
        --context $VAULT_CLUSTER_CONTEXT \
        --namespace $VAULT_NAMESPACE \
        --patch-file tmp/vault-patch.yaml
}

restart_pods(){
    printf "\nRestarting Vault pods\n"
    kubectl delete pod vault-0 \
        --context $VAULT_CLUSTER_CONTEXT \
        --namespace $VAULT_NAMESPACE
    
    printf "\nWaiting for vault-0 to come up...\n"
    while [[ $pod_status != '"Running"' ]]
    do
        sleep 1
        pod_status=$(kubectl get pod vault-0 -n ${VAULT_NAMESPACE} -o json | jq '.status.phase')
        echo "Pod status: " $pod_status
    done

    kubectl delete pod vault-1 \
        --context $VAULT_CLUSTER_CONTEXT \
        --namespace $VAULT_NAMESPACE
}

print_results(){
    printf "\nYou can, now, get secrets with the following commands:\n"

    for role in ${ROLES[@]}
    do
        printf "vault read database/creds/${DATABASE_URI}-${role}\n"
    done
}

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

# Configure Vault with the proper plugin and connection information:
#              GCP   INTANCE/VM
DATABASE_URI=$PROJECT-$INSTANCE-$DATABASE_NAME

# MAIN
enable_postgres_secret_engine

Setup instace and user certs on K8s cluster
insert_secrets_on_k8s
patch_vault_statefulset
restart_pods

config_vault_database

create_roles

create_policies

# Results
print_results
