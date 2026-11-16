---
title: Instalasi Docker
---

Jalankan Kang menggunakan Docker Compose. Siapkan Docker, plugin Compose, Git, dan OpenSSL. Setelah container berjalan, buka http://localhost:3000 dan ikuti setup awal. Image bersifat publik dan tidak memerlukan login registry.

```sh
git clone --depth 1 --branch v3.0.0 https://github.com/zaidanm16/kang-deploy.git
cd kang-deploy/compose
cp backend.env.example backend.env
export BACKEND_IMAGE=ghcr.io/zaidanm16/kang-backend:1.0.0
(umask 077; printf 'JWT_SECRET=%s\nPOSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env)
docker compose up -d
```
