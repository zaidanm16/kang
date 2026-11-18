---
title: Instalasi Kubernetes
---

Instal chart OCI publik menggunakan Helm. Siapkan cluster, kubectl, Helm, serta StorageClass. Konfigurasi default memasang operator CloudNativePG dan memerlukan izin cluster. Buat Secret JWT sebelum instalasi. Gunakan port-forward untuk akses lokal; atur HTTPS untuk akses publik.

```sh
# Buat namespace dan Secret yang berisi kunci penandatanganan JWT backend
kubectl create namespace kang
secret_file="$(mktemp)"
openssl rand -hex 32 > "$secret_file"
kubectl -n kang create secret generic kang-backend-secrets \
  --from-file=JWT_SECRET="$secret_file"
rm -f "$secret_file"

# Instal chart dari registry OCI publik (versi mengikuti rilis)
helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.1.2 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  --set backend.env.AUTH_COOKIE_SECURE=false
```

- Secret di atas menyediakan kunci penandatanganan yang dibutuhkan backend; menjaga Secret di luar values chart menjaganya keluar dari riwayat shell dan record Helm.
- `helm upgrade --install` memasang operator CloudNativePG dan cluster PostgreSQL secara default, yang memerlukan izin cluster-scope.
- `AUTH_COOKIE_SECURE=false` hanya untuk pengujian HTTP lokal — tetap `true` (default) di balik HTTPS.

```sh
# port-forward men tunneling Services in-cluster ke mesin lokal Anda
kubectl -n kang port-forward svc/kang-backend 8080:8080
kubectl -n kang port-forward svc/kang-frontend 3000:3000
```
