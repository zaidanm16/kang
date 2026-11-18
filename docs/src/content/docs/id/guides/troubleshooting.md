---
title: "Pemecahan masalah"
description: "Pemecahan masalah | Kang"
---

## Koneksi gagal
Periksa koneksi terpilih, alamat Admin API, autentikasi, serta akses jaringan dari backend Kang. Untuk 401/403, periksa kredensial dan izin. Untuk timeout, periksa DNS, firewall, dan TLS.

## Resource atau aksi tidak tersedia
Periksa kompatibilitas gateway, role, penugasan tim, serta paket Kang. Bersihkan filter daftar. Pro tidak membuka fitur Kong Enterprise.

## Request proxy gagal
Periksa pencocokan route, host/port service, kesehatan upstream, dan plugin. Uji proxy URL, bukan Admin API.

## Nilai form hilang
Field sensitif dikecualikan dari draft. Draft menggunakan sesi tab saat ini dan bergantung pada penyimpanan browser. Isi ulang secret dan pastikan koneksi benar.

## Grafik kosong
Periksa preferensi Analytics, rentang waktu, trafik sebenarnya, serta integrasi metrik instalasi.

## Lisensi gagal dipasang
Minta administrator global memeriksa key lengkap dan masa berlaku. Lisensi yang dikelola environment memerlukan operator instalasi. Baca [perpanjangan lisensi]((/kang//id/guides/plans/).

Saat melaporkan masalah, sertakan aksi, versi gateway, waktu, serta error yang sudah disamarkan. Jangan menyertakan password, token, private key, atau key lisensi.
