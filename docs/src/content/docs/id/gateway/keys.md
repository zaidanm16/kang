---
title: "Key dan key set"
description: "Key dan key set | Kang"
---

Key dan key set adalah resource kriptografi Kong yang digunakan plugin kompatibel. Keduanya berbeda dari kredensial Key Auth consumer maupun key lisensi Kang Pro.

## Membuat key set

Buka **Keys → Key Sets**, buat set, beri nama yang jelas bila diperlukan, lalu simpan. Set mengelompokkan key yang perlu ditemukan bersama oleh plugin terkait.

## Menambahkan key

1. Buka Keys atau bagian Keys milik key set, lalu pilih aksi membuat key.
2. Isi **Key ID** (`kid`) yang wajib.
3. Masukkan representasi JWK atau PEM yang didukung untuk kebutuhan Anda. Periksa kombinasi wajib pada form/schema; jangan menganggap semua representasi key opsional hanya dari label.
4. Pilih key set jika ingin mengelompokkan key, tambahkan metadata/tag opsional, lalu simpan.
5. Konfigurasikan plugin pengguna agar memakai key atau set yang benar, lalu uji operasi kriptografinya.

Menyimpan key tidak otomatis mengaktifkan autentikasi JWT pada route. Untuk kredensial JWT consumer, gunakan bagian kredensial consumer.

## Rotasi

Pastikan identifier dan material key konsisten. Tambahkan key baru, perbarui aplikasi/plugin pengguna, verifikasi, lalu hapus key lama. Private key atau JWK dapat berisi material sensitif dan tidak dipulihkan dari draft. Periksa referensi sebelum menghapus key atau set; penghapusan bukan sekadar merapikan tampilan.
