---
title: Instalasi Kubernetes
---

Instal chart OCI publik menggunakan Helm. Siapkan cluster, kubectl, Helm, serta StorageClass. Konfigurasi default memasang operator CloudNativePG dan memerlukan izin cluster. Buat Secret JWT sebelum instalasi. Gunakan port-forward untuk akses lokal; atur HTTPS untuk akses publik.

```sh
kubectl create namespace kang
secret_file="$(mktemp)"
openssl rand -hex 32 > "$secret_file"
kubectl -n kang create secret generic kang-backend-secrets \
  --from-file=JWT_SECRET="$secret_file"
rm -f "$secret_file"

helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.0.0 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  --set backend.env.AUTH_COOKIE_SECURE=false
```

```sh
kubectl -n kang port-forward svc/kang-backend 8080:8080
kubectl -n kang port-forward svc/kang-frontend 3000:3000
```
