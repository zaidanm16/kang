---
title: Docker quick start
description: Install Kang with Docker Compose and connect your first gateway.
---


The quickest way to try Kang is with **Docker Compose**. You need Docker with the Compose plugin, `git`, and `openssl`.

```sh
git clone --depth 1 --branch v3.0.0 https://github.com/zaidanm16/kang-deploy.git
cd kang-deploy/compose
cp backend.env.example backend.env
export BACKEND_IMAGE=ghcr.io/zaidanm16/kang-backend:1.0.0
(umask 077; printf 'JWT_SECRET=%s\nPOSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env)
docker compose up -d
```

The published application images are public; registry login is not required.

Open **http://localhost:3000**. Get the one-time setup token with `docker compose logs backend`, then follow the setup screen to create your administrator and connect an existing Kong Admin API. The Admin API must be reachable from the backend container; `localhost` inside a container refers to that container.

This starts the frontend, backend, and PostgreSQL with persistent storage. Kang starts on the Free plan; no license key is required. To stop it, run `docker compose down` from the same directory. Your database is retained.

For public URLs, HTTPS, external services, and updates, see the [Compose guide](https://github.com/zaidanm16/kang-deploy/blob/main/compose/README.md).

