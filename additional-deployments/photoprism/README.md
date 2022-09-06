# Photoprism

```bash
helm repo add p80n https://p80n.github.io/photoprism-helm/
helm repo update
helm upgrade --install photoprism p80n/photoprism --set persistence.enabled=false
```