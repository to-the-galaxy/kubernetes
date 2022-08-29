# Metallb - loadbalancer

`metallb` is used to handle ip addresses for Kubernetes on bare metal.

**Important:** There is an important change between v0.12 and v0.13 with regard to configuration.

## Metallb v0.13.4

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.4/config/manifests/metallb-native.yaml
```

Now, **setup the loadbalancer** by apply:

```bash
# Download the yaml-file from this repo but change the ip-range to your needs
kubectl apply -f metallb-settings-0.13.4.yaml
```

