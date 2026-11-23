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
Minta administrator global atau organisasi memeriksa key lengkap dan masa berlaku. Hanya administrator global yang boleh menghapus lisensi. Lisensi yang dikelola environment memerlukan operator instalasi. Baca [perpanjangan dan backup lisensi](/kang/id/guides/plans/).

## Masalah login atau sesi

| Gejala | Pemeriksaan awal |
| --- | --- |
| Login kembali ke halaman masuk | Pastikan `/auth` mengarah ke backend dan browser menerima cookie sesi dan refresh. Periksa HTTPS, cakupan cookie, kesamaan nama cookie frontend/backend, serta origin frontend dan API. |
| Data terbaca, tetapi perubahan mendapat CSRF 403 | Pastikan browser mengirim cookie CSRF dan header pasangannya ke backend. Periksa CORS dan routing proxy; jangan menonaktifkan CSRF sebagai solusi. |
| Sesi kedaluwarsa atau dicabut | Masuk kembali. Jika login diblokir, minta admin memeriksa status dan penguncian akun. |
| Request mendapat 429 | Hentikan percobaan berulang sampai jendela pembatasan berakhir. Periksa percobaan login berulang atau klien yang berbagi IP. Operator perlu memeriksa batas dan penyimpanan rate limit. |

Saat melaporkan masalah, sertakan aksi, versi gateway, waktu, serta error yang sudah disamarkan. Jangan menyertakan password, token, private key, atau key lisensi.
