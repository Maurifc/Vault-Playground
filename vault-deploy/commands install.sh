# SERVICE is the name of the Vault service in Kubernetes.
# It does not have to match the actual running service, though it may help for consistency.
SERVICE=vault-server-tls

# NAMESPACE where the Vault service is running.
NAMESPACE=vault

# SECRET_NAME to create in the Kubernetes secrets store.
SECRET_NAME=vault-server-tls

# TMPDIR is a temporary working directory.
TMPDIR=./tmp

#
openssl genrsa -out ${TMPDIR}/vault.key 2048

#
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
IP.1 = 127.0.0.1
EOF

#
openssl req -new -key ${TMPDIR}/vault.key -subj "/O=system:nodes/CN=system:node:${SERVICE}.${NAMESPACE}.svc" -out ${TMPDIR}/server.csr -config ${TMPDIR}/csr.conf

#
export CSR_NAME=vault-csr
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

#
kubectl create -f ${TMPDIR}/csr.yaml
kubectl certificate approve ${CSR_NAME}

#
serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')
echo $serverCert

#
echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault.crt

#
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${TMPDIR}/vault.ca

#
kubectl create namespace ${NAMESPACE}

#
kubectl create secret generic ${SECRET_NAME} \
        --namespace ${NAMESPACE} \
        --from-file=vault.key=${TMPDIR}/vault.key \
        --from-file=vault.crt=${TMPDIR}/vault.crt \
        --from-file=vault.ca=${TMPDIR}/vault.ca

# custom values
global:
  enabled: true
  tlsDisable: false

server:
  extraEnvironmentVars:
    VAULT_CACERT: /vault/userconfig/vault-server-tls/vault.ca

  extraVolumes:
    - type: secret
      name: vault-server-tls # Matches the ${SECRET_NAME} from above

  standalone:
    enabled: true
    config: |
      listener "tcp" {
        address = "[::]:8200"
        cluster_address = "[::]:8201"
        tls_cert_file = "/vault/userconfig/vault-server-tls/vault.crt"
        tls_key_file  = "/vault/userconfig/vault-server-tls/vault.key"
        tls_client_ca_file = "/vault/userconfig/vault-server-tls/vault.ca"
      }

      storage "file" {
        path = "/vault/data"
      }

#####################
#
helm install vault hashicorp/vault \
    --namespace ${NAMESPACE} -f custom_values.yaml


#
kubectl exec -ti vault-0 -- vault operator init

#
kubectl exec vault-0 -- vault operator unseal #KEY 1
kubectl exec vault-0 -- vault operator unseal #KEY 2
kubectl exec vault-0 -- vault operator unseal #KEY 3

#
k port-forward svc/vault 8200:8200

#
sudo cp ${TMPDIR}/vault.ca /usr/local/share/ca-certificates/vault.crt
sudo update-ca-certificates

#
sudo echo -n "127.0.0.1       vault-server-tls" > /etc/hosts

# other terminal...
export VAULT_ADDR='https://vault-server-tls:8200'

# test
vault status