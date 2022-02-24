# K8s Cluster aka GKE
Creates a simple GKE cluster

## Service Account
- Create a service account with editor role
- Create a new key for the service account
- Save the json with the key in this folder
- Adjust terraform.tfvars with the key file name

## Enable needed APIs
```
gcloud services enable container.googleapis.com \
                        compute.googleapis.com
```

## Configure before plan
- Check the variables.tf file and set value as needed

