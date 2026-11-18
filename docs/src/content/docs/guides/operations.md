---
title: Operations
description: Inspect deployment health, protect application data, and manage credentials.
---

## Check a Docker deployment

Run these commands from the `compose` directory:

```sh
docker compose ps
docker compose logs --tail=100 backend frontend
```

The backend exposes `/health`; the frontend exposes `/api/health`. If setup cannot reach Kong, verify the Admin API address from the backend's network, not just your browser.

## Public access

For Docker, set `BIND_ADDRESS`, `PUBLIC_API_URL`, and backend `CORS_ORIGINS` for the intended hostnames. Put the frontend and backend behind HTTPS and enable `AUTH_COOKIE_SECURE=true`. Keep database ports and Kong Admin APIs restricted.

For Kubernetes, use the chart's Ingress or Gateway API settings with an installed controller and TLS certificate. See the [chart configuration reference](https://github.com/zaidanm16/kang/blob/main/charts/kang/README.md).

## Credentials

Keep `.env`, `backend.env`, database credentials, and license keys out of Git. Use Kubernetes Secrets or your platform's secret manager. Browser-facing `NEXT_PUBLIC_*` settings are public configuration and must never contain secrets.
