# Terraform Vault Cluster
Provision infraestructure to Vault deployment with:
- VPC
- Public static IP
- GKE Cluster
- Service Account (cluster)
- Service Account (Vault)
- Bucket (Vault Storage Backend)
- Keyring / Key (Vault auto unseal)
- IAM

## Requirements
### Create Terraform service account
- Setup a service account with editor role for terraform auth
- Create a new key for the service account and save as json
- Copy the keyfile to this folder
- Adjust terraform.tfvars with the key file name

### Add role Cloud KMS Admin to Terraform service account
```bash
PROJECT_ID=<GCP PROJECT ID>
SERVICE_ACCOUNT=<GCP SERVICE ACCOUNT NAME>

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
    --role=roles/cloudkms.admin
```

### Enable necessary APIs
```
gcloud services enable container.googleapis.com \
    cloudkms.googleapis.com \
    compute.googleapis.com
```
### Create a terraform.tfvars file from terraform.tfvars.sample
```bash
cp terraform.tfvars.sample terraform.tfvars
```

### Set variables
- variables.tf
- provider.tf
- terraform.tfvars