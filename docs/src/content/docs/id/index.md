---
title: "Panduan pengguna Kang"
description: "Panduan pengguna Kang | Kang"
---

Kang adalah aplikasi yang Anda jalankan sendiri untuk mengelola **Kong API Gateway**. Gunakan Kang untuk mengatur API, berpindah gateway, memeriksa aktivitas, dan mengelola akses tim.

## Mulai dari kebutuhan Anda

- **Instalasi baru:** [Instal dengan Docker](/kang/id/installation/docker/) atau [Helm](/kang/id/installation/kubernetes/), lalu [selesaikan setup](/kang/id/getting-started/setup/).
- **Tim sudah menggunakan Kang:** masuk dengan akun dari administrator dan baca [Dasar workspace](/kang/id/getting-started/workspace/).
- **Membuat API pertama:** ikuti [Membuat service dan route](/kang/id/getting-started/first-api/).
- **Mengatur akun:** baca [Profil dan keamanan](/kang/id/account/profile/) serta [Tema dan bahasa](/kang/id/account/preferences/).
- **Membutuhkan kolaborasi:** lihat [Free dan Pro](/kang/id/guides/plans/).

## Perbedaan Kang dan Kong

Kong menerima trafik API dan meneruskannya ke aplikasi upstream. Kang mengelola Kong melalui Admin API; Kang bukan proxy gateway. Instalasi Kong dijalankan terpisah.

**User Kang** adalah akun yang masuk ke dashboard. **Consumer Kong** adalah aplikasi atau orang yang menggunakan API Anda. Connection Kang menunjuk sebuah gateway; service, route, dan plugin berada di gateway tersebut.

Kang menyimpan pengguna, definisi koneksi, audit, dan snapshot di database aplikasinya. Snapshot konfigurasi gateway bukan backup seluruh database Kang.

## Fitur yang tersedia

Gateway Manager mencakup service, route, consumer dan consumer group, plugin, konfigurasi Redis, upstream dan target, certificate, SNI, vault, key, serta key set. Dukungan resource bergantung pada versi dan edisi Kong yang dipilih.

Kang Free mencakup maksimal **2 koneksi**, **1 pengguna**, Gateway Manager, dan daftar aktivitas audit. Pro menambahkan kolaborasi, koneksi dan pengguna tanpa batas paket, snapshot, serta detail perubahan audit. Kang Pro tidak memberikan lisensi Kong Enterprise.

Panduan ini mengikuti aplikasi saat ini. Jika tombol tidak tersedia, periksa izin akun, paket Kang, dan kompatibilitas gateway. Nama tombol dalam panduan menggunakan label Inggris sebagai acuan; aplikasi juga menyediakan label terjemahan.
