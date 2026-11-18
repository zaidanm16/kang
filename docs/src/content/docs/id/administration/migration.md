---
title: "Full migration opsional"
description: "Full migration opsional | Kang"
---

**Full Migration** adalah fitur maintenance lanjutan, bukan cara biasa menyalin beberapa service. Secara default fitur disembunyikan dan memerlukan dukungan frontend yang diaktifkan operator, migration worker terkonfigurasi, serta administrator global dengan permission migrasi. Deployment standar tidak menyertakan image migration worker.

Jika aksi tidak terlihat, gunakan [clone dan restore snapshot](/kang/id/administration/snapshots/) untuk pemindahan konfigurasi logis, atau tanyakan operator apakah full migration didukung.

## Jika instalasi mengaktifkannya

1. Sepakati jendela maintenance dan backup terverifikasi bersama operator gateway/database.
2. Buka Full Migration dan isi koneksi PostgreSQL sumber serta target secara privat.
3. Jalankan **preflight** lalu periksa detail database dan kompatibilitas. Selesaikan kegagalan sebelum melanjutkan.
4. Jika target berisi data, bandingkan **Backup & replace** dengan **Logical merge**. Replace mengosongkan target setelah backup lalu menyalin data database; target tidak tersedia selama proses. Logical merge membuka alur Clone Snapshot, bukan memulai job migrasi database.
5. Untuk replacement, konfirmasi trafik serta penulisan database Kong sumber dan target sudah dihentikan, lalu selesaikan konfirmasi eksplisit.
6. Pantau job dan periksa hasil/backup sebelum mengembalikan trafik.

Fitur ini bukan upgrade aplikasi Kang dan tidak menjamin semua pasangan versi Kong/PostgreSQL kompatibel. Jangan menempel kredensial database pada komentar audit, tiket, atau screenshot bersama.
