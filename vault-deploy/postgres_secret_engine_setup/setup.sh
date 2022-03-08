#!/bin/bash

# Check if Vault server is reacheable
check_vault_server(){
    echo "Checking Vault connectivity..."
    vault status > /dev/null

    if [ $? != 0 ];
    then 
        printf "\nFailed when connecting to Vault server. Check if your Vault CLI is properly setup."
        exit 1;
    else
        printf "Vault Server up and running.\n\n"
    fi
}

# Print variable loaded from .env file
print_env(){
    echo "GCP Project: "$PROJECT
    echo "DB Instance: "$INSTANCE
    echo "Database Name: "$DATABASE_NAME
    echo "Database Host: "$DATABASE_HOST
    echo "Database User: "$USER_NAME
    echo "Database Pass: ********"
    echo -n "Roles to create: "
    for role in ${ROLES[@]}
    do
        echo -n "$role "
    done
    echo ""
    echo "Vault Server: "$VAULT_ADDR
    echo "Vault Cluster Context: "$VAULT_CLUSTER_CONTEXT
    echo "Vault Deploy Namespace: "$VAULT_NAMESPACE
    echo "Secret Name: "$SECRET_NAME
}

# Ask if user wants to procceed after check loaded envs
ask_user(){
    printf "\nAre you sure you want to procceed? (yes / no): "
    read ANSWER

    if [ "$ANSWER" != "yes" ] && [ "$ANSWER" != "y" ];
    then
        echo "Aborted by user!"
        exit 1;
    fi
}

# Enable the database secrets engine if it is not already enabled:
enable_postgres_secret_engine(){
    printf "\nEnabling Vault secret database\n"
    vault secrets enable database 
}

# TODO: Uncomment connnection url 
# Config access to target database
config_vault_database(){
    printf "\nWriting database config to Vault\n"  
    
    vault write database/config/$DATABASE_URI \
        plugin_name=postgresql-database-plugin \
        allowed_roles=* \
        connection_url="postgresql://{{username}}:{{password}}@${DATABASE_HOST}:5432/${DATABASE_NAME}?sslmode=verify-ca&sslrootcert=/tmp/${SECRET_NAME}/server-ca.pem&sslcert=/tmp/${SECRET_NAME}/client-cert.pem&sslkey=/tmp/${SECRET_NAME}/client-key.pem" \
        # connection_url="postgresql://{{username}}:{{password}}@${DATABASE_HOST}:5432/${DATABASE_NAME}?sslmode=verify-ca&sslrootcert=/pgsql/${SECRET_NAME}/server-ca.pem&sslcert=/pgsql/${SECRET_NAME}/client-cert.pem&sslkey=/pgsql/${SECRET_NAME}/client-key.pem" \
        username=$USER_NAME \
        password=$PASSWORD
}

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

# Insert a secret on K8s containing postgres ca, certificate and key
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

# Patch vault statefulset due to mount the new secret
patch_vault_statefulset(){

    printf "\nCreating patch from template file\n"
    envsubst < vault-patch.yaml.tpl > tmp/vault-patch.yaml

    printf "\nApplying Patch\n"
    kubectl patch statefulset vault \
        --context $VAULT_CLUSTER_CONTEXT \
        --namespace $VAULT_NAMESPACE \
        --patch-file tmp/vault-patch.yaml
}

# Restart pods to apply patch
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

# Print commands to get a credentials from the recent creted roles
print_results(){
    printf "\nYou can, now, get secrets with the following commands:\n"

    for role in ${ROLES[@]}
    do
        printf "vault read database/creds/${DATABASE_URI}-${role}\n"
    done
}

# Check if .env exists
load_env_file(){
    if [ -f .env ];
    then
        set -a
        source .env;
        set +a
    else
        printf "Error: .env file not found at $(pwd)/\n";
        exit 0;
    fi
}

# Configure Vault with the proper plugin and connection information:
#              GCP   INTANCE/VM
DATABASE_URI=$PROJECT-$INSTANCE-$DATABASE_NAME

# MAIN

# Initialization
load_env_file
check_vault_server
print_env
ask_user

# Enable Postgres Secret Engine
enable_postgres_secret_engine

# Setup secret with certs on Vault server
Setup instace and user certs on K8s cluster
insert_secrets_on_k8s
patch_vault_statefulset
restart_pods

# Setup Vault with database config, roles and policies
config_vault_database
create_roles
create_policies

# Show results
print_results
