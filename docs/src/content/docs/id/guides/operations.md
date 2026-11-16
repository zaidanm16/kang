---
title: Operasional
description: Periksa kesehatan deployment, lindungi data aplikasi, dan kelola kredensial.
---

Periksa status serta log container dari folder compose. Untuk akses publik, atur URL API, CORS, reverse proxy HTTPS, dan cookie secure. Simpan kredensial di secret store atau file environment yang tidak masuk Git.

```sh
docker compose ps
docker compose logs --tail=100 backend frontend
```
