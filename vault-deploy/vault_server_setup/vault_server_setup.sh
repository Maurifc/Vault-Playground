#!/bin/bash

printf "Sourcing envs from .env file\n";
# Check if .env exists
if [ -f ../.env ];
then
    source ../.env;
else
    printf "Error: .env file not found\n";
    exit 1;
fi

printf "\nChanging context to ${CONTEXT_VAULT_CLUSTER}\n";
kubectl config use-context $CONTEXT_VAULT_CLUSTER

if [ $? != 0 ];
then
    printf "Aborting: Can't change context to %s\n" $CONTEXT_VAULT_CLUSTER;
    exit 1;
fi

printf "\nGenerating RSA key\n"
openssl genrsa -out ${TMPDIR}/vault.key 2048

printf "\nCreating CSR config\n"
cat <<EOF >${TMPDIR}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NAMESPACE}
DNS.3 = ${SERVICE}.${NAMESPACE}.svc
DNS.4 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
DNS.5 = external-vault
IP.1 = 127.0.0.1
IP.2 = ${VAULT_HOST}
EOF

printf "\nCreating CSR\n"
openssl req -new -key ${TMPDIR}/vault.key -subj "/O=system:nodes/CN=system:node:${SERVICE}.${NAMESPACE}.svc" -out ${TMPDIR}/server.csr -config ${TMPDIR}/csr.conf

printf "\nCreating K8s CSR\n"
cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  signerName: kubernetes.io/kubelet-serving
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl create -f ${TMPDIR}/csr.yaml

printf "\nTrying to approve certificate\n"
kubectl certificate approve ${CSR_NAME}

printf "\nGetting certificate and CA info from cluster\n"
serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')
echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault.crt
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${TMPDIR}/vault.ca

printf "\nCreating namespace\n"
kubectl create namespace ${NAMESPACE}

printf "\nCreatig secret with cert info\n"
kubectl create secret generic ${SECRET_NAME} \
        --namespace ${NAMESPACE} \
        --from-file=vault.key=${TMPDIR}/vault.key \
        --from-file=vault.crt=${TMPDIR}/vault.crt \
        --from-file=vault.ca=${TMPDIR}/vault.ca

#####################
#
printf "\nInstalling Vault Server\n"
helm install vault hashicorp/vault \
    --namespace ${NAMESPACE} \
    -f custom_values.yaml \
    --version 0.19.0

printf "\nWaiting for Vault Server pods...\n"

while [[ $pod_status != '"Running"' ]]
do
    sleep 1
    pod_status=$(kubectl get pod vault-0 -n ${NAMESPACE} -o json | jq '.status.phase')
    echo "Pod status: " $pod_status
done

printf "\nVault Pod is running\n"

printf "\nPatching service loadbalancer with Static IP\n"
envsubst < service_patch.yaml.tpl > ${TMPDIR}/service_patch.yaml
kubectl patch service vault --namespace $NAMESPACE --patch-file ${TMPDIR}/service_patch.yaml

printf "\nInitializing Vault\nKeys saved at %s\n" $TMPDIR/vault-init
kubectl exec -ti vault-0 --namespace $NAMESPACE -- vault operator init | sed 's/\x1b\[[0-9;]*m//g' >  $TMPDIR/vault-init

printf "Vault deployed!\nGet your keys at %s and CA certificate at %s" $TMPDIR/vault-init $TMPDIR/vault.ca