---
title: "Workspace, tabel, dan draft"
description: "Workspace, tabel, dan draft | Kang"
---

## Navigasi

Sidebar mengelompokkan resource **Gateway Manager** dan administrasi **System**. Pemilih koneksi menentukan gateway untuk halaman gateway. Avatar membuka navigasi akun; **Back to workspace** mengembalikan Anda dari Profile, Preferences, atau Security ke workspace.

Gunakan **Search or jump to** pada header untuk mencari tujuan yang tersedia. Setiap daftar resource memiliki pencarian sendiri serta, bila didukung, filter, pengurutan, ukuran halaman, dan pengaturan kolom. Periksa filter aktif jika resource tidak ditemukan. Hasil pencarian kosong belum tentu berarti gateway kosong.

## Daftar dan detail

1. Pilih koneksi yang dituju.
2. Buka daftar resource, cari nilai yang relevan, lalu pilih namanya untuk melihat detail.
3. Gunakan menu aksi baris untuk operasi yang diizinkan bagi akun Anda.
4. Pada daftar dengan checkbox, periksa pilihan sebelum melakukan aksi massal.

Tombol buku membuka bantuan kontekstual. Field wajib memiliki bintang, tetapi beberapa aturan bersifat kondisional: consumer memerlukan username **atau** custom ID. Baca pesan validasi, bukan mengisi semua field opsional.

## Pemulihan draft

Form create/edit yang mendukung draft menyimpan field non-sensitif pada session storage tab browser. Refresh tab dapat memulihkan field tersebut. Draft dipisahkan berdasarkan pengguna, koneksi, halaman, dan konteks resource; draft belum menjadi konfigurasi gateway yang tersimpan.

Password, token, private key, field kredensial, dan beberapa konfigurasi plugin sengaja tidak disimpan. Isi kembali setelah refresh. Pemulihan tidak dijamin ketika penyimpanan browser diblokir, dibersihkan, atau sesi tab berakhir. Jangan mengandalkannya untuk berpindah perangkat.

Mengganti koneksi saat mengedit memunculkan konfirmasi membuang form. Untuk mempertahankan konteks pengeditan, gunakan **open in new tab** pada koneksi lain. Alur simpan/buang yang berhasil membersihkan draft terkait.

## Menghapus resource

Periksa nama resource di modal konfirmasi dan ketik ulang bila diminta. Setelah berhasil, penghapusan memengaruhi gateway atau record Kang terkait. Menghapus koneksi Kang berbeda dari menghapus resource Kong. Gunakan [snapshot](/kang-deploy/id/administration/snapshots/) jika membutuhkan salinan konfigurasi gateway sebelum perubahan.
