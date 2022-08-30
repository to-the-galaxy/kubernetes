# Traefik

**Assumptions**

| Parameter       | Value or attribute       | Comment                                                      |
| --------------- | ------------------------ | ------------------------------------------------------------ |
| Install method  | `helm`                   | `traefik` may be installed in other ways.                    |
| `cert-manager`  | required                 |                                                              |
| certificate     | default or custom        | If custom certificate is not found, then `traefik` defaults to its default non-third party signed certificate. |
| dashboard       | true                     | Dashboard is enabled                                         |
| loadbalancer ip | 192.168.100.240          | Set the value needed in the traefik-values-helm.yaml, which is passed to `helm` |
| user name       | admin                    | Dashboard user                                               |
| password        | dashboard                | Password of the user of dashboard                            |
| ingress route   | local.mydomainexample.io | Remember configure DNS to route traffic to local.example.io towards 192.186.100.240 |



### Install with Helm chart and verify

```bash
# Add Traefik to Helm repo
helm repo add traefik https://helm.traefik.io/traefik

# Update repo
helm repo update

# Create namespace
kubectl create namespace traefik

# Install use traefik-values-helm from this repo
helm upgrade --install traefik -n traefik traefik/traefik -f traefik-values-helm.yaml
```

**Verify**

```bash
# Check pods are running
kubectl get pods -n traefik

# Check services
kubectl get svc --all-namespaces -o wide
   
# Check all CRDs are created (*.traefik.containo.us)
kubectl get crd | grep traefik
```

### Default headers value

```
kubectl apply -f traefik-middleware-default-headers.yaml
```

**Verify**

```
kubectl get middleware
```

### Access Traefik dashboard with password

#### Configure password for Traefik

```bash
# Create password
htpasswd -nb admin dashboard | openssl base64

# Add the output to a secret in data.users
cat <<EOF > secret-dashboard.yaml
apiVersion: v1
kind: Secret
metadata:
  name: traefik-dashboard-auth
  namespace: traefik
type: Opaque
data:
  users: YWRtaW46JGFwcjEkQXhWd0JJMGskTkg0dzZLQW9xTHBkOVRWNDBWV2dPLgoK
EOF
kubectl apply -f secret-dashboard.yaml
```

**Varify**

```bash
kubectl get secret -n traefik
```

#### Create ingressroute for Traefik dashboard

```bash
kubectl apply -f traefik-middleware-dashboard.yaml

# Remember to customise the ingress rule
kubectl apply -f traefik-ingress.yaml
```

**Remember** to create a DNS recoard. This can be done, for example on the client computer by adding a rule to `/etc/hosts`.

```
local.mydomainexample.io
```

`curl` **certificate**

```
curl --insecure -vvI https://local.mydomainexample.io 2>&1 | awk 'BEGIN { cert=0 } /^\* SSL connection/ { cert=1 } /^\*/ { if (cert) print }'
```

### Optional: Whoami-deployment with ingressroute

This whoami-deployment can be used for testing:

```
kubectl apply -f whoami-deployment-service-ingressroute.yaml
```

**Test** (DNS-record is required the domain)

```
local.mydomainexample.io/whoami
```