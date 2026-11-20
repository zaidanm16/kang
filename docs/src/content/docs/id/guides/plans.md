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

## Konfigurasi lisensi melalui UI

Backend memerlukan `KANG_LICENSE_PUBLIC_KEYS`, yaitu objek JSON yang memetakan ID key ke public key Ed25519 berformat base64. Dapatkan objek ini dari penerbit lisensi. Public key memverifikasi tanda tangan, bukan menerbitkan lisensi. Jangan memasukkan private signing key ke container, Helm values, Kubernetes Secret yang dipakai aplikasi, atau Git.

Biarkan `KANG_LICENSE` tidak terpasang atau kosong. Aplikasi akan membaca token yang tersimpan di database; administrator global dapat memasang, mengganti, atau menghapusnya melalui `/license`. Restart backend tidak menghapus lisensi yang dipasang melalui database.

Untuk Compose, tempatkan objek public key di `backend.env`. Untuk Helm, simpan sebagai `KANG_LICENSE_PUBLIC_KEYS` di Secret yang dirujuk `backend.secret.existingName`; chart meneruskan Secret tersebut melalui `envFrom`. Gunakan `backend.extraEnv` dengan `valueFrom.secretKeyRef` jika memerlukan referensi eksplisit. Jangan commit token atau nilai rahasia ke values file.

### Beralih dari environment ke UI

1. Simpan Helm values saat ini dan backup database/Secret. Ikuti [prosedur pembaruan Helm](/kang/id/guides/operations/#memperbarui-release-helm-yang-sudah-ada).
2. Selama lisensi environment masih valid, periksa halaman lisensi. Backend menyimpan token valid tersebut di `license_states`; pertahankan row ini agar lisensi tetap aktif selama peralihan.
3. Hapus `KANG_LICENSE` dari `backend.env`, `backend.extraEnv`, serta Secret atau ConfigMap yang diteruskan melalui `envFrom`. Menghapus entri eksplisit di deployment saja tidak cukup jika Secret `envFrom` masih memuat token. Pertahankan `JWT_SECRET`, `KONG_CREDENTIAL_ENCRYPTION_KEY`, dan `KANG_LICENSE_PUBLIC_KEYS`.
4. Terapkan values melalui Helm dengan versi chart yang sama, lalu pastikan pod backend restart menggunakan environment baru. Perubahan Secret eksternal saja tidak me-restart pod.
5. Pastikan lisensi Pro sebelumnya tetap valid dan keterangan environment-managed hilang. Jika sudah berlisensi, pilih **Actions → Replace** dan tempel token baru. Jika masih Free, pilih **Install Pro license**.

Jangan menghapus row lisensi atau memilih **Remove** hanya untuk mengaktifkan penggantian melalui UI: tindakan itu mengubah paket menjadi Free.

## Meminta lisensi bertanda tangan

Halaman ini tidak menerbitkan lisensi. Dapatkan token Pro bertanda tangan lengkap dari penyedia lisensi, lalu ikuti **Install Pro license** atau **Actions → Replace** di atas. Jaga kerahasiaan token selama transfer, dan jangan mengedit isi atau melampirkannya ke tiket publik, screenshot, atau issue tracker.

Operator menerima token secara privat dan memasangnya lewat UI. Token disimpan di database aplikasi, bukan browser atau file konfigurasi. Pembuatan dan penandatanganan token baru menjadi tanggung jawab penerbit lisensi beserta runbook private-key yang terlindungi; runbook itu tidak termasuk dokumentasi publik ini.

## Memperpanjang atau mengganti

Pada instalasi berlisensi, gunakan **Actions → Replace** lalu pasang key pengganti. Periksa tanggal kedaluwarsa baru. Perpanjangan mengubah lisensi, bukan mengganti database aplikasi atau konfigurasi gateway.

Jika halaman menyatakan lisensi dikelola oleh `KANG_LICENSE`, penggantian/penghapusan melalui UI tidak tersedia. Minta operator memperbarui token deployment atau mengikuti prosedur peralihan ke UI di atas.

## Kedaluwarsa

Pro memiliki **masa tenggang 7 hari** setelah kedaluwarsa. Selama tenggang, fitur Pro tetap tersedia dan UI memperingatkan tanggal penguncian. Setelahnya, akses aplikasi Kang terkunci; login dan pengelolaan lisensi tetap tersedia. Data dipertahankan, dan trafik gateway Kong berjalan secara terpisah.

Kegagalan validasi juga bisa membatasi akses; penyebabnya belum tentu lisensi kedaluwarsa. Minta operator memeriksa konfigurasi verifikasi. Free sendiri tidak memiliki masa kedaluwarsa.

## Kembali ke Free

Administrator global dapat memakai **Actions → Remove** lalu mengonfirmasi, kecuali lisensi dikelola environment. Tindakan ini mengaktifkan Free secara eksplisit; bukan downgrade otomatis saat kedaluwarsa. Koneksi, pengguna, dan data lain tetap ada. Pembuatan koneksi/pengguna baru diblokir selama pemakaian mencapai atau melebihi batas Free, dan fitur khusus Pro tidak tersedia. Jangan menganggap record lama otomatis dihapus atau dinonaktifkan agar memenuhi kuota.
