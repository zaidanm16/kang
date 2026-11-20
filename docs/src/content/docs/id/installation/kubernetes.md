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
  --version 3.1.4 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  --set backend.env.AUTH_COOKIE_SECURE=false
```

- Secret di atas menyediakan kunci penandatanganan yang dibutuhkan backend; menjaga Secret di luar values chart menjaganya keluar dari riwayat shell dan record Helm.
- `helm upgrade --install` memasang operator CloudNativePG dan cluster PostgreSQL secara default, yang memerlukan izin cluster-scope.
- `AUTH_COOKIE_SECURE=false` hanya untuk pengujian HTTP lokal — tetap `true` (default) di balik HTTPS.

## Menggunakan operator CloudNativePG yang sudah ada

Jika cluster sudah memiliki operator CNPG, **set `cnpg.operator.enabled: false`**. Pertahankan `cnpg.cluster.enabled: true` agar chart hanya membuat `Cluster` PostgreSQL untuk Kang, bukan operator kedua:

```yaml
cnpg:
  operator:
    enabled: false
  cluster:
    enabled: true
```

Simpan dalam values file dan tambahkan `-f kang-values.yaml` pada perintah instalasi di atas. Pastikan operator yang ada sehat, CRD `clusters.postgresql.cnpg.io` tersedia, dan operator memantau namespace Kang. Operator boleh berjalan di namespace berbeda; tidak perlu memasang operator kedua khusus Kang.

Pengaturan ini membuat **cluster database baru** yang dikelola operator tersebut, bukan memakai database PostgreSQL yang sudah ada. Untuk memakai database yang sudah ada, nonaktifkan juga `cnpg.cluster.enabled` dan konfigurasikan Secret DSN eksternal sesuai panduan chart. Jangan menonaktifkan/menghapus operator yang dikelola Helm pada release berjalan tanpa memeriksa kepemilikan serta database lain yang dikelolanya.

## Upload foto

Foto profil dan logo organisasi memerlukan kredensial Cloudinary di backend. Ikuti [konfigurasi Cloudinary](/kang/id/guides/operations/#mengaktifkan-upload-foto-dengan-cloudinary) menggunakan Kubernetes Secret; kredensial hanya opsional jika fitur upload tidak diperlukan.

## Akses lokal

```sh
# port-forward meneruskan Service dalam cluster ke mesin lokal Anda
kubectl -n kang port-forward svc/kang-backend 8080:8080
kubectl -n kang port-forward svc/kang-frontend 3000:3000
```
