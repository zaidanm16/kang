# Docker Compose deployment

Run the published frontend and backend images with PostgreSQL stored in a named Docker volume. Docker Engine and the Docker Compose plugin are required. Kong Gateway is managed separately.

## Start

The fastest start is in the [Getting started guide](../README.md#getting-started). The release archive contains this `compose` directory; use the commands below from the extracted release directory or a repository clone.

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

For a new installation, generate a third independent random value for `KONG_CREDENTIAL_ENCRYPTION_KEY` in `backend.env`. Keep it with database backups: it decrypts saved Kong authentication credentials. If omitted, the backend uses `JWT_SECRET` as key material. Do not change the effective key on an existing database without re-encrypting its credentials. See [migration and key rotation](https://zaidanm16.github.io/kang/guides/operations/).

## Gateway analytics (optional)

The dashboard can show traffic, latency, and error analytics. Kang reads metrics from a Prometheus-compatible store; Kong is external, so you wire three things together:

1. **Enable Kong's prometheus plugin** and expose its status listener (`KONG_STATUS_LISTEN=0.0.0.0:8100` on the Kong data plane). Metrics are served at `:8100/metrics`.
2. **Run a metrics store** that scrapes that endpoint, for example VictoriaMetrics attached to the network Kong uses:

   ```sh
   cat > vm.yml <<'EOF'
   global:
     scrape_interval: 15s
   scrape_configs:
     # job_name must match the hostname of the Kang connection's Proxy URL
     - job_name: localhost
       static_configs:
         - targets: ["kong-data-plane:8100"]
   EOF

   docker run -d --name victoria-metrics -p 127.0.0.1:9090:9090 \
     -v "$PWD/vm.yml:/etc/vm.yml:ro" -v victoria-metrics-data:/victoria-metrics-data \
     victoriametrics/victoria-metrics:latest \
     -httpListenAddr=:9090 -storageDataPath=/victoria-metrics-data \
     -promscrape.config=/etc/vm.yml
   ```

   Attach the container to a network that can reach the Kong data plane (for example `--network` of your Kong deployment), or target the host address.
3. **Point the backend at the store:** set `PROMETHEUS_URL=http://victoria-metrics:9090` in `backend.env` and `docker compose up -d backend` again.

Then turn on analytics in the app (per-user preference, Profile → Preferences, or the button on the Overview page). Full walkthrough, Prometheus variant, Kubernetes chart values, and troubleshooting: [Monitoring and analytics](https://zaidanm16.github.io/kang/guides/monitoring/).

## URLs and external services

For access from another machine, set `BIND_ADDRESS=0.0.0.0`, set `PUBLIC_API_URL` to a browser-reachable backend URL, and set `CORS_ORIGINS` in `backend.env` to the frontend origin. Update the public URL when changing `BACKEND_PORT`.

For HTTPS behind a reverse proxy, route frontend requests to port 3000 and API requests to port 8080. Set `PUBLIC_API_URL` and `CORS_ORIGINS` to the public origins and `AUTH_COOKIE_SECURE=true`. This deployment does not install a reverse proxy or certificates.

For external PostgreSQL or MySQL, set `DB_DRIVER` in `backend.env`, replace `backend.environment.DATABASE_DSN` in `compose.yaml`, remove its PostgreSQL dependency, and remove the bundled PostgreSQL service. For Redis-backed rate limiting, set `RATE_LIMIT_STORE=redis` and `RATE_LIMIT_REDIS_URL`. Set `PROMETHEUS_URL` for an existing Prometheus-compatible query API. `localhost` inside a container refers to that container; use a reachable hostname or a service on a shared Docker network. PostgreSQL is started by this Compose file; Redis and metrics services are external. Without a metrics URL, the backend uses its own default `http://prometheus:9090`.

To manage licenses through the UI, configure the issuer's `KANG_LICENSE_PUBLIC_KEYS` in `backend.env` and leave `KANG_LICENSE` unset. A global administrator can paste the signed license at **System → Kang License**; replacements use **Actions → Replace**. The token is stored in PostgreSQL, so it survives container replacement. Setting a nonempty `KANG_LICENSE` overrides the stored token and disables UI installation/replacement/removal. Never deploy a signing private key. See [license configuration and issuance](https://zaidanm16.github.io/kang/guides/plans/).

## Update, logs and data

```sh
docker compose logs -f --tail=100
docker compose pull
docker compose up -d
docker compose down
```

Change image tags in `.env` to select releases. Back up the database before backend upgrades. `docker compose down` preserves the named volume; `docker compose down -v` deletes it and its PostgreSQL data. Use `pg_dump` to take a consistent PostgreSQL backup before upgrading.
