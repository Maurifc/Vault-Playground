#!/bin/bash

# Abort script when something fails
set -e

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
    echo
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

create_policy_file(){
    printf "Creating policy file\n"
    envsubst < policy.hcl.tpl > tmp/policy.hcl
}

select_role(){
    printf "\nSelect auth method: \n"
    vault auth list | tail -n+3 | grep kubernetes | awk '{print $1}'

    printf "\n>"
    read auth_method 

    printf "\nSelect an existing role or type 'n' to create a new: \n"
    vault list auth/$auth_method/role | tail -n+3

    printf "\n>"
    read role
}
# MAIN

# Initialization
load_env_file
check_vault_server
print_env
ask_user


# Select an available auth method
select_role

# Create policy file
create_policy_file

# Review changes

# Apply changes
#vault policy write $POLICY_NAME policy-file.hcl





# # Create role for Kubernetes Auth Method
# printf "\nCreating kubenetes access role\n";
#                              thorus/development/mailapi/config | replace / with - | remove /config
# vault write auth/$ENVIRONMENT/role/$ENVIRONMENT-$APP_NAMESPACE-$APP_NAME \
#         bound_service_account_names=$APP_NAME-sa \
#         bound_service_account_namespaces=$APP_NAMESPACE \
#         policies=$ENVIRONMENT-$APP_NAMESPACE-$APP_NAME \
#         ttl=24h