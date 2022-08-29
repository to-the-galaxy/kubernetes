# Install cert-manager

Cert-manager will be installed in the namespace `cert-manager`. Install with `kubectl`:

```bash
# Namespace
kubectl create namespace cert-manager

# Apply crds
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml

# Create values file
cat <<EOF > cert-manager-values.yaml
installCRDs: false
replicaCount: 3
extraArgs:
  - --dns01-recursive-nameservers=1.1.1.1:53,9.9.9.9:53
  - --dns01-recursive-nameservers-only
podDnsPolicy: None
podDnsConfig:
  nameservers:
    - "1.1.1.1"
    - "9.9.9.9"
EOF

# Helm install
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --values=cert-manager-values.yaml --version v1.9.1

# Create API token on Cloudflare.com

# Create secret with API token from Cloudflare.com not the global API key
cat <<EOF > secret-cf-token.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-token-secret
  namespace: cert-manager
type: Opaque
stringData:
  cloudflare-token: B4cDlPJ6rlqKRrGKl3abARS1AcvdoAZhDtph8kbO
EOF
kubectl apply -f secret-cf-token.yaml

# Letsencrypt
cat <<EOF > letsencrypt-staging.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: name.example@icloud.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
      - dns01:
          cloudflare:
            email: name.example@icloud.com
            apiTokenSecretRef:
              name: cloudflare-token-secret
              key: cloudflare-token
        selector:
          dnsZones:
            - "example.io"
EOF
kubectl apply -f letsencrypt-staging.yaml

# Create cluster certificate
cat <<EOF > local-example-io.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: local-example-io
  namespace: default
spec:
  secretName: local-example-io-staging-tls
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  commonName: "*.example.io"
  dnsNames:
  - "*.example.io"
EOF
kubectl apply -f local-example-io.yaml
```



```bash
kubectl get certificates
kubectl get challenges --all-namespaces
kubectl get all -n cert-manager
```



**It may take some time**