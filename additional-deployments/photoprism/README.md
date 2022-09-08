# Photoprism

These are install notes from installing Photoprism from using this helm repository: https://p80n.github.io/photoprism-helm/. Photoprism was installed in a Kubernetes cluster (v.1.24.0) with `containerd` as runtime.

Some important observations and troubleshooting:

* Photoprism needs a 4G of available ram.
* As persistent storage an nfs-server is used. (Make sure that the machine in which the cluster or node is running can mount the storage).
* Because of the use of an nfs-server, these install notes does not make use of Kubernetes persistent volume and persistent volume claim (but those can be used as well).
* Photoprism needs a web domain or ip address without a pathprefix. For example `photoprism.local.example.io` and `192.168.100.242` worked, but `local.example.io/photoprism` did not.

```bash
# From the server (or elsewhere with access to the Kubernetes cluster)

# Add helm repo
helm repo add p80n https://p80n.github.io/photoprism-helm/

# Update helm repo
helm repo update

# Install
helm upgrade --install photoprism p80n/photoprism --values <values>
```

For testing purposes one can use non-persistent storage:

````
helm upgrade --install photoprism p80n/photoprism --set persistence.enabled=false
```