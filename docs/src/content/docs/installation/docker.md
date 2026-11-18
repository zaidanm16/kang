---
title: Docker quick start
description: Install Kang with Docker Compose and connect your first gateway.
---


The quickest way to try Kang is with **Docker Compose**. You need Docker with the Compose plugin, `git`, and `openssl`.

```sh
# Clone the deployment files at the current release
git clone --depth 1 --branch v3.1.0 https://github.com/zaidanm16/kang-deploy.git
cd kang-deploy/compose
# Create backend configuration from the example (backend-only variables like CORS and session settings)
cp backend.env.example backend.env
export BACKEND_IMAGE=ghcr.io/zaidanm16/kang-backend:1.0.0
# Generate two random secrets into .env: JWT_SECRET signs login sessions, POSTGRES_PASSWORD secures the database
(umask 077; printf 'JWT_SECRET=%s\nPOSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env)
# Start the stack in the background: PostgreSQL, backend, and frontend
docker compose up -d
```

Open **http://localhost:3000**. Run `docker compose logs backend` to get the one-time setup token, then follow the setup screen to create your administrator and connect an existing Kong Admin API. The Admin API must be reachable from the backend container; `localhost` inside a container refers to that container.

- `backend.env` — backend process settings: `CORS_ORIGINS` (the frontend origin), rate limits, session lifetimes. See the [backend environment reference](https://github.com/zaidanm16/kang-backend/blob/main/.env.example) for everything.
- `docker compose logs backend` — prints the one-time setup token.
- `docker compose down` — stops the stack but keeps your database; add `-v` to delete it.

This starts the frontend, backend, and PostgreSQL with persistent storage. Kang starts on the Free plan; no license key is required. To stop it, run `docker compose down` from the same directory. Your database is retained.

For public URLs, HTTPS, external services, and updates, see the [Compose guide](https://github.com/zaidanm16/kang-deploy/blob/main/compose/README.md).

