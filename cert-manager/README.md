# Certificates on Kubernetes with cert-manager

## Install with `helm`

Cert-manager will be installed in the namespace `cert-manager`. Install with `kubectl`:

```bash
# Namespace
kubectl create namespace cert-manager

# Apply crds
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml

# Helm install (use the yaml-file from this repo)
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --values=helm-values-cert-manager.yaml --version v1.9.1
```

## Create API-token on Cloudflare.com

**Assumptions**

| Attribute                                     | Value                                    |
| --------------------------------------------- | ---------------------------------------- |
| domain name                                   | mydomainexample.oi                       |
| email                                         | myemail@mymail.oi                        |
| API Token                                     | fake_token_ym9jr33kAHySk7gAL33FOXQxR5GrX |
| K8s secret for Cloudfare API Token            | cloudflare-api-token-secret              |
| K8s clusterissuer                             | letsencrypt-staging-clusterissuer        |
| K8s certificate (signing request) (name)      | mydomainexample-io-certificate           |
| K8s certificate (signing request) (namespace) | traefik                                  |

**Create API token** www.cloudflare.com:

1. On the main menu select **My Profile**
2. Click on **API Tokens**
3. Click **Create Token**
   * Give a descriptive token name
   * Two sets of permission: a) **Zone, Zone, Read**, and b) **Zone, DNS, Edit**
   * **Copy the token**, because it will only be **shown once** and **keep it secret**!
4. Click on the domain you need in this tutorial the domainname is: **mydomainexample.oi**

## Configure cluster to use SSL/TSL

First save **Cloudfare API token** in a kubernetes **secret**

```bash
# Create token based on template in this repo
kubectl apply -f cloudflare-api-token-secret.yaml
```

Now, create a **Clusterissuer** that uses letsencrypt-stagning (don't go to production on letsencrypt until everyting is working perfect):

```bash
# Apply clusterissuer based on template in this repo
kubectl apply -f letsencrypt-staging-clusterissuer.yaml
```

"A `Certificate` resource specifies fields that are used to generate certificate signing requests which are then fulfilled by the issuer type you have referenced. `Certificates` specify which issuer they want to obtain the certificate from by specifying the `certificate.spec.issuerRef`field."[Source](https://cert-manager.io/docs/usage/certificate/)

Now, **create a certificate request**

```bash
# Use template in this repo
kubectl apply -f mydomainexample-io-certificate.yaml
```

## Check status (it may take 15 min.)

```bash
kubectl get certificates
kubectl get challenges --all-namespaces
kubectl get all -n cert-manager
```

## Troubleshooting

First:

```bash
kubectl get clusterissuer

kubectl get certificates --all-namespaces

kubectl get certificaterequest

kubectl get secret -A

kubectl describe secret <name-of-secret>

kubectl logs -n traefik traefik-<pod id>

# If output is similar to
NAME                     READY   SECRET                   AGE
<name-of-certificate>    False   <name>-staging-tls       19m

# Get more info by
kubectl describe certificate <name-of-certificate>

# Output sample
Events:
  Type    Reason     Age   From                    Message
  ----    ------     ----  ----                    -------
  Normal  Issuing    20m   cert...trigger          Issuing certificate as Secret does not exist
  Normal  Generated  20m   cert...key-manager      Stored ... temporary ..."<name-of-certificate>vsz8b"
  Normal  Requested  20m   cert...request-manager  ...CertificateRequest ... "<name-of-certificate>sqzzm"
  
# Get info on the request
kubectl describe certificaterequest <name-of-certificate>sqzzm
```

