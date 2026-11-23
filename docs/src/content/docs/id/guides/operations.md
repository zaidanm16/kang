---
title: Operasional
description: Periksa kesehatan deployment, lindungi data aplikasi, dan kelola kredensial.
---

Periksa status serta log container dari folder compose. Untuk akses publik, atur URL API, CORS, reverse proxy HTTPS, dan cookie secure. Simpan kredensial di secret store atau file environment yang tidak masuk Git.

```sh
docker compose ps
docker compose logs --tail=100 backend frontend
```

Backend menyediakan `/health`, frontend menyediakan `/api/health`. Periksa alamat Admin API dari jaringan backend, bukan hanya dari browser. Batasi akses ke port database dan Admin API Kong.

## Kredensial

Jangan commit `.env`, `backend.env`, kredensial database, atau token lisensi. Gunakan Kubernetes Secret atau secret manager. Konfigurasi `NEXT_PUBLIC_*` terlihat oleh browser dan tidak boleh berisi secret.

`KONG_CREDENTIAL_ENCRYPTION_KEY` melindungi kredensial Admin API Kong yang tersimpan, bukan password database atau tanda tangan lisensi. Tetapkan nilai acak terpisah dan stabil sebelum menyimpan koneksi berautentikasi pertama. Jika kosong, backend menggunakan `JWT_SECRET` sebagai key material; mengganti JWT secret tersebut juga memengaruhi dekripsi kredensial. Verifikasi lisensi memakai `KANG_LICENSE_PUBLIC_KEYS` yang terpisah; lihat [pengelolaan lisensi](/kang/id/guides/plans/).

## Mengaktifkan upload foto dengan Cloudinary

Foto profil dan logo organisasi diunggah oleh backend ke **Cloudinary**. Untuk memakai fitur ini, buat product environment Cloudinary dan ambil ketiga pengaturan berikut dari halaman API Keys:

```dotenv
CLOUDINARY_CLOUD_NAME=nama-cloud-anda
CLOUDINARY_API_KEY=api-key-anda
CLOUDINARY_API_SECRET=api-secret-anda
```

Untuk Docker Compose, tambahkan pengaturan ini ke file privat `backend.env`, lalu buat ulang container backend. Untuk Helm, gunakan Kubernetes Secret, bukan values `backend.env` (values tersebut dirender menjadi ConfigMap). Contohnya, simpan tiga baris dengan nilai asli di `/secure/cloudinary.env`, batasi akses file hanya untuk pemiliknya, lalu buat Secret terpisah:

```sh
kubectl -n kang create secret generic kang-cloudinary \
  --from-env-file=/secure/cloudinary.env
```

Tambahkan referensi ini ke Helm values hasil ekspor tanpa menghapus entri `extraEnvFrom` yang sudah ada:

```yaml
backend:
  extraEnvFrom:
    - secretRef:
        name: kang-cloudinary
```

Ikuti prosedur pembaruan Helm di bawah. Jika hanya isi Secret yang berubah, restart pod backend agar nilai baru terbaca. Jangan mengekspos API secret melalui `NEXT_PUBLIC_*`, melakukan commit, atau menulis kredensial asli di dokumentasi.

Backend memerlukan akses HTTPS keluar ke Cloudinary; browser memerlukan akses ke URL gambar `res.cloudinary.com` yang dikembalikan. Upload mendukung PNG, JPEG, dan WebP dengan batas **5 MB**. Tanpa ketiga pengaturan tersebut, upload tidak tersedia. Untuk verifikasi, unggah foto profil atau logo organisasi uji melalui akun berizin, lalu pastikan gambar tetap tampil setelah refresh. Jika gagal, periksa kredensial, koneksi keluar, dan batas akun Cloudinary tanpa mencatat secret.

File gambar disimpan di Cloudinary; database Kang menyimpan URL-nya. Backup/kelola aset media secara terpisah dari database aplikasi. Gambar dikirim melalui URL, jadi jangan mengunggah dokumen rahasia sebagai foto.

## Memperbarui release Helm yang sudah ada

Ekspor values release yang terpasang sebelum mengeditnya. Sebutkan context dan namespace agar tidak mengubah instalasi yang salah. Contoh memakai release `kang` di namespace `kang`; ganti `destination-context` dan versi chart sesuai instalasi Anda.

```sh
umask 077
CTX=destination-context
NS=kang
RELEASE=kang
helm list --kube-context "$CTX" -n "$NS"
helm get values "$RELEASE" --kube-context "$CTX" -n "$NS" -o yaml > values.current.yaml
helm get manifest "$RELEASE" --kube-context "$CTX" -n "$NS" > manifest.current.yaml
cp values.current.yaml values.updated.yaml
```

Edit `values.updated.yaml` sambil mempertahankan pengaturan database, storage, gateway, image, dan resource lainnya. Rujuk Secret backend, bukan menyalin isi secret ke values:

```yaml
backend:
  secret:
    existingName: kang-backend-secrets
  extraEnv:
    - name: KONG_CREDENTIAL_ENCRYPTION_KEY
      valueFrom:
        secretKeyRef:
          name: kang-backend-secrets
          key: KONG_CREDENTIAL_ENCRYPTION_KEY
    - name: KANG_LICENSE_PUBLIC_KEYS
      valueFrom:
        secretKeyRef:
          name: kang-backend-secrets
          key: KANG_LICENSE_PUBLIC_KEYS
```

Ini potongan konfigurasi, bukan pengganti seluruh values hasil ekspor. Secret harus sudah memuat key yang dirujuk. Pertahankan `JWT_SECRET` dan entri lain saat memperbarui Secret melalui secret manager atau patch yang terarah. Chart juga meneruskan `backend.secret.existingName` melalui `envFrom`, sehingga referensi eksplisit bersifat opsional kecuali perlu menimpa sumber environment lain. Jangan pasang `KANG_LICENSE` di sumber mana pun untuk lisensi yang dikelola melalui UI.

```sh
helm upgrade "$RELEASE" oci://ghcr.io/zaidanm16/kang \
  --version 3.1.3 \
  --kube-context "$CTX" -n "$NS" \
  -f values.updated.yaml --wait --timeout 5m
```

Untuk perubahan konfigurasi saja, pertahankan versi chart yang sedang terpasang; jangan downgrade instalasi yang lebih baru mengikuti versi contoh. Periksa dry-run sebelum apply dan lindungi output-nya karena manifest Helm dapat memuat Secret. Restart pod backend jika hanya Secret eksternal yang berubah: environment proses lama tidak diperbarui otomatis.

Hindari `kubectl set env` untuk konfigurasi Helm permanen. Perubahan manual sebelumnya dapat memicu conflict kepemilikan field pada Helm 4 server-side apply. Periksa field yang dilaporkan; gunakan `--force-conflicts` hanya setelah memastikan Helm memang harus mengambil alih perubahan tersebut. Opsi itu berbeda dari `--force-replace`. Simpan values dan Secret sebelumnya untuk rollback, lalu periksa request API terautentikasi setelah rollout, bukan hanya kesiapan pod.

## Backup dan pemulihan CNPG

Memasang atau memakai operator CloudNativePG yang sudah ada tidak otomatis mengatur backup. Di produksi, siapkan penyimpanan backup di luar cluster dan jadwalkan backup dengan `ScheduledBackup` yang menunjuk `Cluster` database Kang. Pilih metode yang didukung versi operator dan plugin yang terpasang. Untuk pemulihan ke titik waktu tertentu (PITR), arsipkan WAL dan backup dasar, lalu pastikan keduanya sampai ke penyimpanan. Lihat [panduan backup CloudNativePG](https://cloudnative-pg.io/documentation/current/backup/).

Simpan salinan terpisah dan terlindungi untuk Helm values, Secret aplikasi, token lisensi, dan backup media. Uji pemulihan di **cluster database baru**. Periksa versi PostgreSQL, titik pemulihan, role aplikasi, serta kepemilikan objek, lalu hubungkan backend Kang uji dengan encryption key yang cocok. Periksa login, akses koneksi gateway tersimpan, dan status lisensi sebelum mengalihkan trafik. Job backup yang sukses belum membuktikan restore berhasil.

## Memindahkan database aplikasi Kang

Database Kang menyimpan akun, hash password, organisasi, tim, izin, koneksi, preferensi sesi, audit log, snapshot, dan riwayat migrasi. Versi baru juga menyimpan status setup dan lisensi. Database ini **tidak** menyimpan service, route, plugin, atau consumer aktif milik Kong Gateway. Jika gateway tetap sama, jangan mengubah database Kong.

1. Catat versi backend/PostgreSQL sumber dan tujuan. Gunakan dump client yang kompatibel dengan server sumber dan tujuan yang didukung backend baru. Jangan membuang riwayat migrasi untuk memaksakan downgrade skema Kang.
2. Backup kedua database beserta secret yang relevan. Pertahankan `KONG_CREDENTIAL_ENCRYPTION_KEY` efektif sumber; jika menggunakan fallback JWT, simpan key material tersebut secara eksplisit. Backup upload filesystem atau object storage secara terpisah. Password/role database dikelola terpisah dari dump.
3. Saat cutover akhir, hentikan penulis database aplikasi sumber dan semua replika/job backend tujuan. Catat jumlah replika untuk dipulihkan setelah selesai. Trafik gateway Kong boleh tetap berjalan hanya jika Kong sendiri berada di luar migrasi ini.
4. Ambil dump custom-format terakhir. Utamakan restore ke database tujuan baru yang kosong dan dimiliki role aplikasi. Jangan menggabungkannya dengan skema baru yang sudah dibuat backend tujuan atau menganggap `--clean --if-exists` menghapus semua dependensi khusus tujuan. Mengganti database tujuan yang sudah ada memerlukan backup terverifikasi dan persetujuan eksplisit.

Contoh mengasumsikan PostgreSQL service definition `kang-source` dan `kang-restore` sudah dikonfigurasi secara privat, dengan password di passfile berizin `0600`. `kang-restore` harus menunjuk database tujuan baru yang kosong; role yang terhubung harus boleh menjalankan `SET ROLE kang`:

```sh
umask 077
pg_dump --dbname="service=kang-source" --format=custom --file=kang-source.dump
pg_restore --list kang-source.dump > kang-source.contents
pg_restore --dbname="service=kang-restore" \
  --role=kang --no-owner --no-acl \
  --single-transaction --exit-on-error kang-source.dump
```

`--no-owner` mengabaikan perintah ownership sumber; objek baru tetap dimiliki role yang melakukan restore. Restore sebagai `postgres` tanpa `--role=kang` dapat membuat aplikasi gagal mengubah tabel saat upgrade. GRANT tidak memberikan ownership. Periksa dengan `SELECT schemaname, tablename, tableowner FROM pg_tables WHERE schemaname = 'public';`. Koreksi hanya objek aplikasi; jangan menjalankan `REASSIGN OWNED BY postgres` secara menyeluruh terhadap objek sistem.

5. Arahkan DSN Secret deployment tujuan ke database hasil restore. Pertahankan database lama dan backup untuk rollback. Jalankan satu replika backend dengan `MIGRATE_ON_START=true`; backend memakai riwayat `schema_migrations` dari sumber untuk menerapkan migrasi tertunda. Periksa log sebelum mengembalikan jumlah replika normal.
6. Pada versi dengan initial setup, proses inisialisasi mengenali user yang sudah ada ketika membuat status setup. Database lama yang berisi user seharusnya tidak meminta pembuatan administrator baru. Jika row `setup_states` tujuan tertinggal akibat restore parsial, selidiki penyebabnya, bukan membuat administrator duplikat.
7. Bandingkan jumlah row sumber dan hasil restore, termasuk soft-deleted row. Login, tampilkan koneksi melalui API terautentikasi, periksa tim/permission, audit log, dan snapshot, lalu uji koneksi Kong berautentikasi dari jaringan backend. Pod sehat dan jumlah row cocok belum membuktikan dekripsi kredensial berhasil.

Port-forward PostgreSQL terikat ke satu pod walaupun target perintahnya Service; koneksi tidak berpindah otomatis jika pod hilang. Pantau proses dan log-nya. Connection reset saja bukan bukti OOM atau korupsi database. Jika tunnel tidak stabil, stream arsip melalui `kubectl exec -i` ke `pg_restore` di pod tujuan. Filesystem container CNPG dapat read-only, jadi jangan menganggap `/tmp` bisa ditulis. Hentikan proses pada error restore pertama; jangan menyembunyikan exit status melalui `head` atau `grep`.

## Merotasi encryption key kredensial Kong

Mengganti nilai environment saja membuat kredensial terenkripsi lama tidak terbaca. Belum ada CLI rotasi bawaan atau transisi multi-key. Pertahankan key yang sudah ada sampai prosedur rotasi teruji dan maintenance window tersedia.

Implementasi backend ada di [secrets/cipher.go](https://github.com/zaidanm16/kang-backend/blob/main/internal/secrets/cipher.go): key AES-256-GCM adalah **SHA-256 dari teks UTF-8 environment yang persis sama** setelah konfigurasi membuang whitespace di tepi. Nilai dari `openssl rand -hex 32` tetap diperlakukan sebagai teks: **jangan** hex-decode menjadi byte key AES mentah. Format tersimpan adalah `enc:v1:` diikuti base64url tanpa padding yang memuat nonce 12 byte serta ciphertext/tag autentikasi GCM.

1. Backup database, key lama, deployment values, dan Secret saat ini. Pastikan setiap kredensial tersimpan yang tidak kosong dapat didekripsi dengan key sumber. Jangan mencetak plaintext ke log atau file sementara.
2. Hentikan seluruh penulis/replika backend agar proses key lama dan baru tidak mencampur ciphertext. Buat secret pengganti dan turunkan key tepat seperti backend.
3. Dekripsi dengan key turunan lama lalu enkripsi ulang dengan key turunan baru, memakai nonce acak baru untuk setiap kredensial. Pertahankan nilai kosong dan semua field selain kredensial. Jalankan update dalam satu transaksi dengan pengaman terhadap perubahan bersamaan; rollback seluruh batch bila satu saja gagal.
4. Perbarui Secret dan values/referensi Helm bersama-sama, lalu restart backend dengan environment baru. Jangan membiarkan pod dengan key lama melayani database yang sudah dienkripsi ulang.
5. Verifikasi **seluruh** ciphertext terdampak dapat didekripsi dengan derivasi backend dan plaintext-nya sama di memori. Lalu periksa `/api/v1/user/kong-instances` terautentikasi, halaman lisensi, dan koneksi Kong nyata. Pemeriksaan kripto harus mengikuti derivasi aplikasi, bukan hanya memakai helper yang sama dengan penulis data yang mungkin keliru.

Simpan key lama bersama backup lama sampai masa retensinya berakhir. Rollback harus memulihkan pasangan ciphertext **dan** key material yang cocok; mengembalikan hanya env atau hanya database mengulangi mismatch. Rotasi key ini tidak memerlukan penerbitan lisensi atau penggantian signing key.
