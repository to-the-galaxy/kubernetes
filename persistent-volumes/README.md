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

Make `pv-1.yaml` with this content

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: foo-pv
spec:
  capacity:
    storage: 70Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  storageClassName: slow
  mountOptions:
    - hard
    - nfsvers=4.1
  nfs:
    path: /export/share1
    server: 192.168.1.247
```

Apply the pv:

```bash
kubectl apply -f pv-1.yaml
```

**Check if there are warnings!!!**

```bash
kubectl get events --all-namespaces  --sort-by='.metadata.creationTimestamp'
```
