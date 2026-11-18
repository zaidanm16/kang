---
title: Arsitektur
description: Bagaimana frontend, backend, database, dan Kong Admin API Kang saling terhubung.
---

Kang terdiri dari dua komponen aplikasi yang berjalan berdampingan: **frontend Next.js** dan **backend Go**. Backend mengelola semua data Kang dan seluruh komunikasi dengan Kong.

![Diagram arsitektur Kang](/kang/diagrams/architecture-id.svg)

## Komponen

| Komponen | Teknologi | Peran |
|---|---|---|
| Frontend | Next.js (App Router), React, Material UI, TanStack Query | UI dashboard; memeriksa cookie sesi di routing dan menampilkan antarmuka dalam beberapa bahasa |
| Backend | Go dengan Gin, GORM | Seluruh logika bisnis: autentikasi, RBAC, proxy Kong Admin API, snapshot, audit, metrik, lisensi |
| Database | PostgreSQL, MySQL, atau SQLite | Data aplikasi Kang. Konfigurasi milik Kong tersimpan di Kong, bukan di sini |
| Kong Gateway | Instance Kong Anda yang sudah ada | Melayani lalu lintas API. Kang hanya berkomunikasi dengan Admin API-nya |

Bundle Compose menjalankan frontend, backend, dan PostgreSQL dengan penyimpanan persisten. Helm chart menginstal komponen yang sama di Kubernetes dan secara bawaan juga menginstal operator CloudNativePG untuk PostgreSQL.

## Alur request

1. Browser membuka frontend. Middleware Next.js memeriksa cookie `kang_session` dan mengarahkan pengunjung yang belum masuk ke `/login`.
2. UI memanggil backend langsung di `/api/v1` (dikonfigurasi lewat `NEXT_PUBLIC_API_URL`). Request membawa cookie sesi HttpOnly, header `X-CSRF-Token`, dan header `X-Kong-Instance-ID` yang memilih koneksi gateway aktif. Saat menerima 401, UI memperbarui sesi secara senyap lalu mencoba ulang.
3. Backend memvalidasi sesi JWT, token CSRF, dan izin rute sebelum menjalankan logika bisnis. Data role dan izin tersimpan di database Kang.
4. Request resource Kong diteruskan oleh proxy backend: `POST|GET|... /api/v1/kong-proxy/*` ditulis ulang ke Admin URL milik koneksi terpilih. Kredensial Kong tersimpan terenkripsi di database Kang dan tidak pernah sampai ke browser.

## Autentikasi dan akses

- Sesi berupa JWT dalam cookie HttpOnly: access token berumur pendek ditambah refresh token yang dipersisten. Access token bawaan berlaku 15 menit; refresh bawaan 7 hari, atau 30 hari dengan "remember me".
- Kontrol akses berupa RBAC di database: role dan izin seperti `instances.read` atau `snapshots.create` diperiksa per rute. Akses ke instance Kong juga dibatasi berdasarkan keanggotaan tim.
- Setup awal menggunakan token sekali pakai dari log startup backend; tidak ada akun administrator bawaan.

## Layanan latar belakang dan opsional

- **Prometheus atau VictoriaMetrics**: saat `PROMETHEUS_URL` diatur dan analytics aktif, backend mengambil metrik lalu lintas untuk dashboard Overview. Cache Redis/DragonflyDB opsional mempercepat query dashboard berulang.
- **Database migration worker**: proses terpisah opsional yang dipakai administrator untuk migrasi penuh database Kang, lengkap dengan pemeriksaan awal dan backup.
- **OpenTelemetry**: ekspor tracing OTLP opsional.

## Kompatibilitas Kong

Kang mendeteksi versi dan edisi Kong di setiap koneksi. Pengelolaan gateway inti membutuhkan Kong 2.0.0 atau lebih baru; dukungan penuh dimulai dari 3.10.0, dan rilis diuji hingga 3.15. Fitur yang tidak didukung dinonaktifkan per koneksi.
