# Persistent volumes

* Persistent volumes
* Persistent volume claims

## Storage on a nfs-share

### Pre-flight checks

Before trying to use an nfs-share for persistent storage, make sure that
the nodes used can actually mount the nfs-share.

**Example** where the nfs-share is located on `192.168.1.247` in a folder called
`/export/share1`:

```bash
# Mount
sudo mount -o rw 192.168.1.247:/export/share1 /mnt/test

# Write and output sample text
echo "Hallo World ls!" > /mnt/test/test.txt
cat /mnt/test/test.txt

# Clean up
rm /mnt/test/test.txt

# Unmount. Make sure you are not in the folder you try to unmount.
umount -f /mnt/test
```

### Create a persistent volume

Make `nfs-pv.yaml` with this content

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  nfs:
    server: 192.168.1.247
    path: "/export/share1"
```

Apply the pv:

```bash
kubectl apply -f pv-1.yaml
```

**Check if there are warnings!!!**

```bash
kubectl get events --all-namespaces  --sort-by='.metadata.creationTimestamp'
```

### Create a persistent volume claim

Make `nfs-pvc.yaml` and apply with `kubectl apply -f nfs-pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  resources:
    requests:
      storage: 100Mi
```

**Check**

```bash
kubectl get pvc

# Output sample:
NAME   STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
nfs    Bound    nfs      500Mi      RWX            nfs            20m
```

### Create a pod that uses the nfs-share

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-web
  template:
    metadata:
      labels:
        app: nfs-web
    spec:
      containers:
      - name: nfs-web
        image: nginx
        ports:
          - name: web
            containerPort: 80
        volumeMounts:
          - name: nfs
            mountPath: /usr/share/nginx/html
      volumes:
      - name: nfs
        persistentVolumeClaim:
          claimName: nfs
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nfs-web
  name: nfs-web-svc
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nfs-web
  type: LoadBalancer
```

**Check by entering the pod** and locate the nfs-share.

```bash
kubectl exec -it local-web-695c7975c7-42csl -- /bin/bash
```

and/or **check** by opening the website in a browser.
