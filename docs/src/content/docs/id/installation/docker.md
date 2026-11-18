---
title: Instalasi Docker
---

Jalankan Kang menggunakan Docker Compose. Siapkan Docker, plugin Compose, Git, dan OpenSSL. Setelah container berjalan, buka http://localhost:3000 dan ikuti setup awal.

```sh
# Clone file deployment pada rilis terkini
git clone --depth 1 --branch v3.1.1 https://github.com/zaidanm16/kang.git
cd kang/compose
# Buat konfigurasi backend dari contoh (variabel backend seperti CORS dan sesi)
cp backend.env.example backend.env
export BACKEND_IMAGE=ghcr.io/zaidanm16/kang-backend:1.1.0
# Generate dua secret acak ke .env: JWT_SECRET menandatangani sesi login, POSTGRES_PASSWORD mengamankan database
(umask 077; printf 'JWT_SECRET=%s\nPOSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env)
# Jalankan stack di background: PostgreSQL, backend, dan frontend
docker compose up -d
```
