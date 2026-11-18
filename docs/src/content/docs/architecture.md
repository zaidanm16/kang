---
title: Architecture
description: How Kang's frontend, backend, database, and Kong Admin API fit together.
---

Kang has two application components that run next to each other: a **Next.js frontend** and a **Go backend**. The backend owns all Kang data and all communication with Kong.

![Kang architecture diagram](/kang/diagrams/architecture-en.svg)

## Components

| Component | Technology | Role |
|---|---|---|
| Frontend | Next.js (App Router), React, Material UI, TanStack Query | Dashboard UI; gates page routes on the session cookie and renders the interface in multiple languages |
| Backend | Go with Gin, GORM | All business logic: auth, RBAC, Kong Admin API proxy, snapshots, audit, metrics, licensing |
| Database | PostgreSQL, MySQL, or SQLite | Kang's application data. Kong's own configuration lives in Kong, not here |
| Kong Gateway | Your existing Kong instance | Serves API traffic. Kang only talks to its Admin API |

The Compose bundle ships the frontend, backend, and PostgreSQL with persistent storage. The Helm chart installs the same components on Kubernetes and by default also installs the CloudNativePG operator for PostgreSQL.

## Request flow

1. The browser opens the frontend. Next.js middleware checks the `kang_session` cookie and redirects unauthenticated visitors to `/login`.
2. The UI calls the backend directly at `/api/v1` (configured by `NEXT_PUBLIC_API_URL`). Requests carry the HttpOnly session cookie, a `X-CSRF-Token` header, and an `X-Kong-Instance-ID` header that selects the active gateway connection. On a 401 the UI silently refreshes the session and retries.
3. The backend validates the JWT session, CSRF token, and route permissions before running business logic. Role and permission data is stored in the Kang database.
4. Kong resource requests are forwarded by the backend's proxy: `POST|GET|... /api/v1/kong-proxy/*` is rewritten onto the selected connection's stored Admin URL. Kong credentials are stored encrypted in the Kang database and never reach the browser.

## Authentication and access

- Sessions are JWTs in HttpOnly cookies: a short-lived access token plus a persisted refresh token. Access-token lifetime defaults to 15 minutes; refresh defaults to 7 days, or 30 days with "remember me".
- Access control is database-backed RBAC: roles and permissions such as `instances.read` or `snapshots.create` are checked per route. Access to a Kong instance is additionally scoped by team membership.
- First-run setup uses a one-time token from the backend startup logs; there is no default administrator account.

## Background and optional services

- **Prometheus or VictoriaMetrics**: when `PROMETHEUS_URL` is configured and analytics is enabled, the backend queries traffic metrics and serves the Overview dashboard. Optional Redis/DragonflyDB caches speed up repeated dashboard queries.
- **Database migration worker**: an optional separate process used by administrators for full Kang database migrations, with preflight checks and backups.
- **OpenTelemetry**: optional OTLP tracing export.

## Kong compatibility

Kang detects each connection's Kong version and edition. Core gateway management requires Kong 2.0.0 or later; full support starts at 3.10.0, and releases are tested through 3.15. Unsupported features are disabled per connection.
