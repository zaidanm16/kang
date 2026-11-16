---
title: "Free, Pro, dan perpanjangan lisensi"
description: "Free, Pro, dan perpanjangan lisensi | Kang"
---

Lisensi Kang berlaku untuk **seluruh instalasi Kang**, bukan satu tab browser atau gateway Kong. Kelola melalui **System → Kang License** (`/license`). Halaman ini tidak mengelola lisensi Kong Enterprise.

## Perbandingan paket

| Fitur | Free | Pro |
| --- | --- | --- |
| Gateway Manager | Akses penuh sesuai dukungan Kong dan izin akun | Tetap mengikuti kompatibilitas gateway |
| Koneksi | Maksimal **2** | Tidak dibatasi paket |
| Pengguna | **1** | Tidak dibatasi paket |
| Organisasi dan tim | Tidak termasuk | Termasuk |
| Snapshot | Tidak termasuk | Termasuk |
| Audit log | Daftar aktivitas | Aktivitas dan detail perubahan |
| Masa berlaku | Tidak kedaluwarsa | Mengikuti tanggal lisensi |

Tanpa lisensi, instalasi baru menggunakan Free. Batas koneksi dan pengguna menghitung record seluruh instalasi. Pro menghapus batas paket, bukan batas kapasitas infrastruktur atau pemeriksaan izin akun.

## Upgrade ke Pro

1. Dapatkan lisensi Pro bertanda tangan dari penyedia Kang Anda. Aplikasi memasang key; aplikasi tidak menyediakan checkout pembelian atau menerbitkan key untuk Anda.
2. Masuk sebagai **administrator global**: akun admin tanpa penugasan organisasi.
3. Buka Kang License lalu pilih **Install Pro license**.
4. Tempel key lengkap pada dialog lalu instal.
5. Pastikan paket, penerima lisensi, dan tanggal kedaluwarsa benar. Kembali ke fitur yang dituju dan periksa akses sesuai permission akun.

Jangan mengedit isi key. Jika instalasi gagal, periksa kelengkapan key, waktu berlakunya, dan minta operator memeriksa konfigurasi lisensi instalasi. Administrator organisasi tidak dapat memasang lisensi hanya karena role-nya bernama admin.

## Memperpanjang atau mengganti

Pada instalasi berlisensi, gunakan **Actions → Replace** lalu pasang key pengganti. Periksa tanggal kedaluwarsa baru. Perpanjangan mengubah lisensi, bukan mengganti database aplikasi atau konfigurasi gateway.

Jika halaman menyatakan lisensi dikelola oleh `KANG_LICENSE`, hubungi operator instalasi untuk memperbarui nilai deployment tersebut lalu me-restart backend. Penggantian/penghapusan melalui UI tidak tersedia untuk lisensi yang dikelola environment.

## Kedaluwarsa

Pro memiliki **masa tenggang 7 hari** setelah kedaluwarsa. Selama tenggang, fitur Pro tetap tersedia dan UI memperingatkan tanggal penguncian. Setelahnya, akses aplikasi Kang terkunci; login dan pengelolaan lisensi tetap tersedia. Data dipertahankan, dan trafik gateway Kong berjalan secara terpisah.

Kegagalan validasi juga bisa membatasi akses; penyebabnya belum tentu lisensi kedaluwarsa. Minta operator memeriksa konfigurasi verifikasi. Free sendiri tidak memiliki masa kedaluwarsa.

## Kembali ke Free

Administrator global dapat memakai **Actions → Remove** lalu mengonfirmasi, kecuali lisensi dikelola environment. Tindakan ini mengaktifkan Free secara eksplisit; bukan downgrade otomatis saat kedaluwarsa. Koneksi, pengguna, dan data lain tetap ada. Pembuatan koneksi/pengguna baru diblokir selama pemakaian mencapai atau melebihi batas Free, dan fitur khusus Pro tidak tersedia. Jangan menganggap record lama otomatis dihapus atau dinonaktifkan agar memenuhi kuota.
