# Docker Compose deployment

Run the published frontend and backend images with PostgreSQL stored in a named Docker volume. Docker Engine and the Docker Compose plugin are required. Kong Gateway is managed separately.

## Start

From the repository root:

```sh
cd compose
cp .env.example .env
cp backend.env.example backend.env
openssl rand -hex 32
```

Use hexadecimal passwords (`openssl rand -hex 32`) so the password is safe inside the PostgreSQL URI. For other passwords, percent-encode reserved characters in the DSN only. Generate two independent values and set `JWT_SECRET` and `POSTGRES_PASSWORD` in `.env`, then run:

```sh
docker compose pull
docker compose up -d
docker compose ps
```

Open http://localhost:3000. The browser connects to the API at http://localhost:8080; the frontend server connects internally to `http://backend:8080`. Both published ports bind to loopback by default. `depends_on` controls startup order; it does not wait for API readiness. Check `/health` on the backend and `/api/health` on the frontend if startup fails.

`.env` configures Compose image names, published ports, browser API URL and JWT secret. `backend.env` configures the backend process. Both local files are ignored by Git. Keep the JWT secret stable across restarts. See [all backend environment settings](https://github.com/zaidanm16/kang-backend/blob/main/.env.example) for additional supported settings; `SERVER_PORT`, `DATABASE_DSN`, and `JWT_SECRET` are set explicitly by Compose.

## URLs and external services

For access from another machine, set `BIND_ADDRESS=0.0.0.0`, set `PUBLIC_API_URL` to a browser-reachable backend URL, and set `CORS_ORIGINS` in `backend.env` to the frontend origin. Update the public URL when changing `BACKEND_PORT`.

For HTTPS behind a reverse proxy, route frontend requests to port 3000 and API requests to port 8080. Set `PUBLIC_API_URL` and `CORS_ORIGINS` to the public origins and `AUTH_COOKIE_SECURE=true`. This deployment does not install a reverse proxy or certificates.

For external PostgreSQL or MySQL, set `DB_DRIVER` in `backend.env`, replace `backend.environment.DATABASE_DSN` in `compose.yaml`, remove its PostgreSQL dependency, and remove the bundled PostgreSQL service. For Redis-backed rate limiting, set `RATE_LIMIT_STORE=redis` and `RATE_LIMIT_REDIS_URL`. Set `PROMETHEUS_URL` for an existing Prometheus-compatible query API. `localhost` inside a container refers to that container; use a reachable hostname or a service on a shared Docker network. PostgreSQL is started by this Compose file; Redis and metrics services are external. Without a metrics URL, the backend uses its own default `http://prometheus:9090`.

Signed Kang licenses and public verification keys can be provided through `backend.env`, or install a license in the application's Kang License page. Never deploy a signing private key. License state and PostgreSQL data persist in the backend volume.

## Update, logs and data

```sh
docker compose logs -f --tail=100
docker compose pull
docker compose up -d
docker compose down
```

Change image tags in `.env` to select releases. Back up the database before backend upgrades. `docker compose down` preserves the named volume; `docker compose down -v` deletes it and its PostgreSQL data. Use `pg_dump` to take a consistent PostgreSQL backup before upgrading.
