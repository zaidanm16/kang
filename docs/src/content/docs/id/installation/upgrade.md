---
title: Pembaruan
description: Backup database aplikasi lalu tingkatkan Kang ke versi baru.
---

Backup database aplikasi sebelum setiap pembaruan. Untuk PostgreSQL, gunakan backup yang konsisten seperti `pg_dump`. Snapshot konfigurasi gateway bukan pengganti backup database aplikasi Kang.

## Docker Compose

Ubah tag image aplikasi pada `.env` (misalnya `BACKEND_IMAGE`), lalu jalankan:

```sh
docker compose pull
docker compose up -d
```

`docker compose down` mempertahankan volume database. Opsi `-v` menghapus volume beserta datanya.

## Kubernetes

Arahkan `--version` ke versi chart baru dan atur tag image aplikasi baru pada values Anda, lalu jalankan:

```sh
helm upgrade kang oci://ghcr.io/zaidanm16/kang \
  --version <versi-chart-baru> \
  --namespace kang \
  -f values.updated.yaml
```

Mulai `values.updated.yaml` dari hasil ekspor release terpasang, bukan defaults chart. Ikuti [prosedur pembaruan Helm](/kang/id/guides/operations/#memperbarui-release-helm-yang-sudah-ada) agar Secret, penyimpanan, dan konfigurasi gateway tetap terjaga.

## Jika rollout gagal

Periksa log startup backend dan pastikan apakah migrasi database sudah berjalan sebelum rollback. Rollback Helm atau kembali ke image Compose lama memulihkan konfigurasi atau biner aplikasi, **bukan schema database, Secret eksternal, atau data**. Pakai image lama dengan database saat ini hanya jika versi tersebut mendukung schema dan riwayat migrasinya.

Jika tidak kompatibel, hentikan proses yang menulis data dan pulihkan database serta Secret pra-upgrade yang cocok ke target terpisah. Periksa data setelah upgrade yang mungkin hilang sebelum cutover. Setelah pulih, uji login, lisensi, dan minimal satu koneksi gateway berautentikasi, bukan hanya readiness.

## Catatan rilis

Baca catatan rilis setiap versi di antara versi Anda saat ini dan versi tujuan untuk mengetahui perubahan yang tidak kompatibel sebelum memperbarui.
