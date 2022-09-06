# Longhorn for persistent storage





### The basic setup

Follow these steps to setup Longhorn with Helm:

```bash
# Required packages (probably already installed) 
sudo apt install open-iscsi bash curl grep
sudo apt install open-iscsi bash curl grep original-awk util-linux -y
# awk blkid lsblk findmnt

helm repo add longhorn https://charts.longhorn.io
helm repo update
helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
kubectl -n longhorn-system get pod
kubectl -n longhorn-system get svc

# Create password
htpasswd -nb admin dashboard | openssl base64

# Add the output to a secret in data.users
cat <<EOF > secret-longhorn-dashboard.yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-dashboard-auth
  namespace: longhorn-system
type: Opaque
data:
  users: YWRtaW46JGFwcjEkL3d5eEdxa3QkZEhaNS41QXdULlpCTEI5dDhxQ2pXMQoK
EOF
kubectl apply -f secret-longhorn-dashboard.yaml

kubectl get secret --all-namespaces

#
cat <<EOF > longhorn.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: longhorn-ui
  name: longhorn-frontend
  namespace: longhorn-system
spec:
  ports:
  - port: 8000
    protocol: TCP
    targetPort: 8000
    name: websecure
  selector:
    app: longhorn-ui
---
kind: IngressRoute
apiVersion: traefik.containo.us/v1alpha1
metadata:
  name: longhorn-frontend
  namespace: longhorn-system
  annotations: 
    kubernetes.io/ingress.class: traefik-external
spec:
  entryPoints: 
  - websecure
  routes:
  - match: Host(\`local.mydomainexample.io\`) && (PathPrefix(\`/longhorn\`))
    kind: Rule
    services:
    - name: longhorn-frontend
      port: 8000
    middlewares:
    - name: stripprefixmw
      namespace: longhorn-system
    - name: longhorn-dashboard-auth
      namespace: longhorn-system
  - match: Host(\`longhorn.mydomainexample.io\`)
    kind: Rule
    services:
    - name: longhorn-frontend
      port: 8000
    middlewares:
    - name: longhorn-dashboard-auth
      namespace: longhorn-system
  tls:
    secretName: local-mydomainexample-io-staging-tls
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: longhorn-dashboard-auth
  namespace: longhorn-system
spec:
  basicAuth:
    secret: longhorn-dashboard-auth
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: stripprefixmw
  namespace: longhorn-system
spec:
  stripPrefix:
    prefixes:
      - /longhorn
    forceSlash: false
EOF
kubectl apply -f longhorn.yaml
```

