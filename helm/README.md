# Helm - Package manager for Kubernetes

Assumtions about the environment in which `helm` will be used:

* Ubuntu 22.04 server
* Kubernetes cluster running with `kubectl` being configured in `<user>/home/.kube`

## Install

```bash
sudo su -

curl https://baltocdn.com/helm/signing.asc | apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

apt update && apt install helm -y
```

## Add recommended repos

```bash
# Add repos (not as sudo):
helm repo add jetstack https://charts.jetstack.io
helm repo add metallb https://metallb.github.io/metallb
helm repo add traefik https://helm.traefik.io/traefik
helm repo add longhorn https://charts.longhorn.io

# Update repo
helm repo update
```

## Commands

**Values** of chart as in repo

```bash
helm show values <chart>
helm show values metallb/metallb
```

**Values** of helm release (deployment)

```bash
helm get values <release> -n <name-space>
```

