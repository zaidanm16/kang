# Kang Helm Chart

![Version: 3.1.2](https://img.shields.io/badge/Version-3.1.2-informational?style=flat-square)  ![AppVersion: 3.1.2](https://img.shields.io/badge/AppVersion-3.1.2-informational?style=flat-square)

- [Kang Helm Chart](#kang-helm-chart)
  - [Introduction](#introduction)
  - [Prerequisites](#prerequisites)
  - [Requirements](#requirements)
  - [Installing the Chart](#installing-the-chart)
    - [Installing the Chart from the OCI Registry](#installing-the-chart-from-the-oci-registry)
    - [Installing the Chart from Sources](#installing-the-chart-from-sources)
      - [Pulling the Chart](#pulling-the-chart)
      - [Installing the Chart](#installing-the-chart-1)
    - [Custom installation options](#custom-installation-options)
      - [Exposing the application](#exposing-the-application)
      - [Database choices](#database-choices)
      - [Optional cache and metrics services](#optional-cache-and-metrics-services)
  - [Upgrading the Chart](#upgrading-the-chart)
  - [Uninstalling the Chart](#uninstalling-the-chart)
  - [Configuration](#configuration)
  - [Operational notes](#operational-notes)
  - [Troubleshooting](#troubleshooting)
  - [License](#license)

## Introduction

This chart deploys [Kang](https://github.com/zaidanm16/kang) in your Kubernetes cluster: the Next.js frontend, the Go backend, and a PostgreSQL database through CloudNativePG by default, plus optional cache, metrics, and networking resources.

Kang is the management application for Kong API Gateway. It manages your existing Kong instances through their Admin APIs; it does not deploy Kong Gateway itself.

## Prerequisites

- [Helm 3.19+](https://helm.sh/docs/intro/install/) or Helm 4. The checked-in CloudNativePG dependency is pinned to chart `0.22.0`.
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- A Kubernetes Secret containing a unique, stable `JWT_SECRET` value, created outside Helm. Keeping credentials outside Helm values avoids writing them into a values file or the Helm release record.

> [!NOTE]
>
> When `cnpg.operator.enabled=true` (the default), the chart installs the [CloudNativePG](https://cloudnative-pg.io/documentation/) operator through its dependency. This needs cluster-scoped permissions. If your cluster policy separates operator administration, install and manage the operator separately and set `cnpg.operator.enabled=false`.

## Requirements

- Kubernetes with a default StorageClass, or a storage class / pre-created PV and claim that matches your values, when persistence is enabled.
- For `networking.mode: ingress`, an installed Ingress controller.
- For `networking.mode: gatewayApi`, Gateway API CRDs and a controller that implements `Gateway` and `HTTPRoute` `gateway.networking.k8s.io/v1`.
- For a private GHCR package, an image pull Secret and its name in `global.imagePullSecrets`. The published application images are public when package visibility permits anonymous pulls.
- For an external PostgreSQL/MySQL database, a Secret key with its DSN.

## Installing the Chart

### Installing the Chart from the OCI Registry

The published chart is public at `oci://ghcr.io/zaidanm16/kang`; cloning this repository is not required. Use `--version 3.1.2` with Helm.

Create a namespace and the backend Secret, then install:

```shell
kubectl create namespace kang
secret_file="$(mktemp)"
trap 'rm -f "$secret_file"' EXIT
openssl rand -hex 32 > "$secret_file"
kubectl -n kang create secret generic kang-backend-secrets \
  --from-file=JWT_SECRET="$secret_file"

helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.1.2 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  --set backend.env.AUTH_COOKIE_SECURE=false
```

`kang` is the name of the release and can be changed. The defaults install the CloudNativePG operator and a PostgreSQL cluster with persistent storage. To access the application locally without an Ingress or Gateway, use two terminals:

```shell
kubectl -n kang port-forward svc/kang-backend 8080:8080
kubectl -n kang port-forward svc/kang-frontend 3000:3000
```

Then open `http://localhost:3000`. The default browser API URL is `http://localhost:8080`, and the backend CORS origin is `http://localhost:3000`. For HTTPS production traffic, expose the application as described below and set `backend.env.AUTH_COOKIE_SECURE=true` (the default).

Use a reviewed values file for repeatable installs rather than long command-line overrides:

```shell
helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.1.2 \
  --namespace kang --create-namespace \
  -f kang-values.yaml \
  --set backend.secret.existingName=kang-backend-secrets
```

Render before applying and review the manifests for your cluster:

```shell
helm template kang oci://ghcr.io/zaidanm16/kang \
  --version 3.1.2 \
  --namespace kang \
  -f kang-values.yaml \
  --set backend.secret.existingName=kang-backend-secrets
```

### Installing the Chart from Sources

#### Pulling the Chart

```shell
git clone --depth 1 --branch v3.1.2 https://github.com/zaidanm16/kang.git
cd kang/charts/kang
helm dependency build
```

#### Installing the Chart

To install the chart into the `kang` namespace from the pulled sources:

```shell
helm install kang . --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets
```

### Custom installation options

#### Exposing the application

Choose one exposure mode. Both templates route `/api/v1`, `/auth`, and `/health` to the backend and all remaining paths to the frontend. This keeps browser API calls on the same origin and avoids adding a second public host or CORS setup. The Services are `ClusterIP`; there is no NodePort or LoadBalancer setting in this chart.

Existing Ingress controller:

```yaml
networking:
  mode: ingress
  host: kang.example.com
  ingress:
    className: nginx
    tls:
      enabled: true
      secretName: kang-example-tls
```

Existing Gateway API Gateway:

```yaml
networking:
  mode: gatewayApi
  host: kang.example.com
  gatewayApi:
    gatewayName: shared-gateway
    gatewayNamespace: edge
    sectionName: https
    tls:
      enabled: true
```

To create a Gateway in the release namespace instead, set `gatewayApi.createGateway: true` and provide `gatewayClassName`. For custom public API origins, set `networking.publicApiUrl` and `backend.env.CORS_ORIGINS` to the exact frontend origin(s), comma-separated.

#### Database choices

| Mode | Values | Notes |
| --- | --- | --- |
| CNPG managed PostgreSQL (default) | `cnpg.cluster.enabled: true`, `cnpg.operator.enabled: true` | CNPG creates its own PVCs and `<cluster>-app` Secret; the backend reads the `uri` key. Configure storage on `cnpg.cluster.storage`. |
| External PostgreSQL | `backend.database.driver: postgres`, `backend.database.dsnSecret.name/key` | Disable both `cnpg.cluster.enabled` and `cnpg.operator.enabled`. |
| External MySQL | `backend.database.driver: mysql`, `backend.database.dsnSecret.name/key` | Same Secret approach; DSN syntax is defined by the backend's MySQL driver. |
| SQLite (optional) | `backend.database.driver: sqlite`, `backend.database.dsn: /data/data.db`, CNPG disabled | Keep the backend at one replica. The backend PVC holds the database file. |

External DSN Secret:

```shell
kubectl -n kang create secret generic kang-database \
  --from-file=DATABASE_DSN=/secure/path/to/database-dsn
```

```yaml
backend:
  database:
    driver: postgres
    dsnSecret:
      name: kang-database
      key: DATABASE_DSN
  persistence:
    enabled: false
```

#### Optional cache and metrics services

No Redis service is required by default: rate limiting uses the backend's in-memory store. Enable an in-chart DragonflyDB (Redis-compatible) instance, or supply an external Redis URL (or a Secret holding it):

```yaml
redis:
  enabled: true
  persistence:
    enabled: true
```

The backend also reuses the configured Redis URL for its optional Kong list, overview, compatibility, and metrics dashboard caches, enabled through `backend.env`.

For dashboard metrics, the backend queries a Prometheus-compatible API at `PROMETHEUS_URL`. Enable an in-chart single-node VictoriaMetrics instance, or point at an external service:

```yaml
metrics:
  enabled: true
  persistence:
    enabled: true
```

The chart configures the backend to use the internal VictoriaMetrics Service. `metrics.scrapeConfig` supplies a Prometheus scrape configuration to that single-node instance; **by default it scrapes nothing** — the chart does not deploy Kong and cannot discover its metrics endpoints. To get real dashboard data, install Kong's `prometheus` plugin, expose its status listener (`KONG_STATUS_LISTEN=0.0.0.0:8100`) through a `Service`, and add a matching scrape job to `metrics.scrapeConfig`:

```yaml
metrics:
  scrapeConfig: |
    global:
      scrape_interval: 15s
    scrape_configs:
      # job_name must match the hostname of the Kang connection's Proxy URL
      - job_name: my-kong-system
        static_configs:
          - targets: ["kong-status.my-kong-system.svc:8100"]
```

Full walkthrough, the Docker Compose variant, and troubleshooting: [Monitoring and analytics](https://zaidanm16.github.io/kang/guides/monitoring/).

## Upgrading the Chart

Back up the application database before every upgrade. Helm does not back up CNPG, SQLite, or metrics data and does not perform cross-engine data migration.

To upgrade the release `kang` from the OCI registry, point `--version` at the new chart version and set the new application image tags in your values:

```shell
helm upgrade kang oci://ghcr.io/zaidanm16/kang \
  --version <new-chart-version> \
  --namespace kang
```

Pin application images to release or commit tags and update both image tags through reviewed values. The backend runs schema migrations on startup when `MIGRATE_ON_START=true` (the default). See the [Upgrade guide](https://zaidanm16.github.io/kang/installation/upgrade/) for the full procedure and release notes guidance.

## Uninstalling the Chart

To uninstall/delete the release `kang`:

```shell
helm uninstall kang -n kang
```

> [!WARNING]
>
> This command removes the Kubernetes components associated with the release, including the CNPG `Cluster` and its PostgreSQL data PVCs. Database and metrics data is deleted and cannot be recovered unless you have backups outside the cluster.

## Configuration

The following table lists the configurable parameters of the Kang chart and their default values.

> More granular configuration options may not show up in this table.
> Viewing the `values.yaml` file directly can show all available options.
> `values.schema.json` validates supported enums and common value types.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity applied to application pods. |
| backend.database.dsn | string | `"/data/data.db"` | DSN used only for the sqlite driver (file path on the mounted PVC). |
| backend.database.dsnSecret.key | string | `"DATABASE_DSN"` | Secret key that holds the database DSN. |
| backend.database.dsnSecret.name | string | `""` | Name of an existing Secret containing the DSN for external PostgreSQL/MySQL. Disables the built-in CNPG database when set. |
| backend.env.ACCESS_LOG_MODE | string | `"important"` | Access log verbosity: all, important, or off. |
| backend.env.ACCESS_TOKEN_TTL | string | `"15m"` | Access token lifetime for login sessions. |
| backend.env.AUDIT_LOG_RETENTION_INTERVAL | string | `"24h"` | Interval between audit retention cleanup runs. |
| backend.env.AUDIT_LOG_RETENTION_PERIOD | string | `"2160h"` | Audit log retention period. Older audit entries are removed. |
| backend.env.AUTH_COOKIE_NAME | string | `"kang_session"` | Session cookie name. Must match frontend AUTH_COOKIE_NAME. |
| backend.env.AUTH_COOKIE_SAMESITE | string | `"lax"` | Session cookie SameSite policy. |
| backend.env.AUTH_COOKIE_SECURE | string | `"true"` | Set true for HTTPS traffic; keep false only for non-TLS local testing. |
| backend.env.AUTH_RATE_LIMIT_REQUESTS | string | `"10"` | Authentication endpoint rate limit requests per window. |
| backend.env.AUTH_RATE_LIMIT_WINDOW | string | `"1m"` | Authentication endpoint rate limit window. |
| backend.env.BCRYPT_COST | string | `"12"` | bcrypt hashing cost for password storage. |
| backend.env.CORS_ALLOW_CREDENTIALS | string | `"true"` | Allow credentialed CORS responses. The backend rejects a wildcard origin with credentials. |
| backend.env.CORS_EXPOSE_HEADERS | string | `"Content-Length"` | Comma-separated CORS exposed headers. |
| backend.env.CORS_HEADERS | string | `"Origin,Content-Type,Accept,Authorization,X-Skip-Audit,X-CSRF-Token,X-Kong-Instance-ID"` | Comma-separated CORS request headers. |
| backend.env.CORS_METHODS | string | `"GET,POST,PUT,PATCH,DELETE,OPTIONS"` | Comma-separated CORS methods. |
| backend.env.CSRF_ENABLED | string | `"true"` | Enable CSRF protection for state-changing requests. |
| backend.env.DB_CONN_MAX_LIFETIME | string | `"1h"` | Maximum lifetime of a database connection. |
| backend.env.DB_MAX_IDLE_CONNS | string | `"10"` | Maximum idle database connections. |
| backend.env.DB_MAX_OPEN_CONNS | string | `"100"` | Maximum open database connections. |
| backend.env.GIN_MODE | string | `"release"` | Gin framework mode. Keep release in production. |
| backend.env.JWT_AUDIENCE | string | `"kang-api"` | JWT audience claim. |
| backend.env.JWT_ISSUER | string | `"kang"` | JWT issuer claim. |
| backend.env.KONG_COMPATIBILITY_CACHE_ENABLED | string | `"false"` | Enable the Redis-backed Kong compatibility cache. |
| backend.env.KONG_COMPATIBILITY_CACHE_PREFIX | string | `"kang:compatibility"` | Redis key prefix for the Kong compatibility cache. |
| backend.env.KONG_COMPATIBILITY_CACHE_TTL | string | `"6h"` | Time-to-live of the Kong compatibility cache. |
| backend.env.KONG_COMPATIBILITY_ERROR_CACHE_TTL | string | `"1m"` | Time-to-live of cached Kong compatibility errors. |
| backend.env.KONG_OVERVIEW_CACHE_ENABLED | string | `"false"` | Enable the Redis-backed overview cache. |
| backend.env.KONG_OVERVIEW_CACHE_PREFIX | string | `"kang:overview"` | Redis key prefix for the overview cache. |
| backend.env.KONG_OVERVIEW_CACHE_TTL | string | `"5m"` | Time-to-live of the overview cache. |
| backend.env.KONG_RECURSIVE_CACHE_ENABLED | string | `"true"` | Enable the Redis-backed recursive Kong list cache. |
| backend.env.KONG_RECURSIVE_CACHE_REDIS_PREFIX | string | `"kang:kong-list"` | Redis key prefix for the recursive Kong list cache. |
| backend.env.KONG_RECURSIVE_CACHE_REDIS_TTL | string | `"5m"` | Redis time-to-live for the recursive Kong list cache. |
| backend.env.KONG_RECURSIVE_CACHE_TTL_MS | string | `"30s"` | In-process time-to-live for the recursive Kong list cache. |
| backend.env.LOGIN_LOCKOUT_DURATION | string | `"15m"` | Account lockout duration after repeated failed logins. |
| backend.env.LOG_LEVEL | string | `"info"` | Backend log verbosity. |
| backend.env.MAX_LOGIN_ATTEMPTS | string | `"5"` | Failed login attempts allowed before account lockout. |
| backend.env.MAX_SESSIONS | string | `"5"` | Maximum concurrent sessions per user. |
| backend.env.MIGRATE_ON_START | string | `"true"` | Run database migrations on backend startup. |
| backend.env.OTEL_EXPORTER_OTLP_ENDPOINT | string | `"http://localhost:4317"` | OpenTelemetry OTLP/gRPC collector endpoint. |
| backend.env.OTEL_SERVICE_NAME | string | `"kang-backend"` | OpenTelemetry service name. |
| backend.env.OTEL_TRACING_ENABLED | string | `"false"` | Enable OpenTelemetry tracing export. |
| backend.env.PASSWORD_MIN_LENGTH | string | `"8"` | Minimum password length enforced by the password policy. |
| backend.env.PASSWORD_REQUIRE_NUMBER | string | `"true"` | Require a number in passwords. |
| backend.env.PASSWORD_REQUIRE_SPECIAL | string | `"true"` | Require a special character in passwords. |
| backend.env.PASSWORD_REQUIRE_UPPER | string | `"true"` | Require an uppercase character in passwords. |
| backend.env.PROMETHEUS_CACHE_ENABLED | string | `"false"` | Enable the Redis-backed metrics dashboard cache. |
| backend.env.PROMETHEUS_CACHE_FRESH_TTL | string | `"1m"` | Time-to-live of fresh dashboard cache entries. |
| backend.env.PROMETHEUS_CACHE_PREFIX | string | `"kang:prometheus-dashboard"` | Redis key prefix for the metrics dashboard cache. |
| backend.env.PROMETHEUS_CACHE_STALE_TTL | string | `"5m"` | Time-to-live served for stale dashboard cache entries. |
| backend.env.PROMETHEUS_TIMEOUT | string | `"30s"` | Timeout for Prometheus-compatible metrics queries. |
| backend.env.PROXY_REQUEST_TIMEOUT | string | `"60s"` | Timeout for proxied Kong Admin API requests. |
| backend.env.RATE_LIMIT_REQUESTS | string | `"120"` | General API rate limit requests per window. |
| backend.env.RATE_LIMIT_STORE | string | `""` | Rate limit store: memory, redis, or empty for automatic selection. |
| backend.env.RATE_LIMIT_WINDOW | string | `"1m"` | General API rate limit window. |
| backend.env.REFRESH_TOKEN_TTL | string | `"168h"` | Refresh token lifetime. |
| backend.env.REMEMBER_ME_REFRESH_TOKEN_TTL | string | `"720h"` | Refresh token lifetime when "remember me" is selected at login. |
| backend.extraEnv | list | `[]` | Extra backend environment entries as standard Kubernetes env items, including valueFrom Secret references. |
| backend.extraEnvFrom | list | `[]` | Extra backend envFrom references, such as an additional Secret or ConfigMap. |
| backend.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| backend.image.repository | string | `"ghcr.io/zaidanm16/kang-backend"` | Backend application image repository. |
| backend.image.tag | string | `"v1.1.0"` | Backend application image tag. Prefer immutable release or SHA tags. |
| backend.persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes of the created PVC. |
| backend.persistence.annotations | object | `{}` | Annotations for the created PVC. |
| backend.persistence.enabled | bool | `true` | Create and mount a PVC for backend-local data such as a SQLite database. Not used in external DB or CNPG modes. |
| backend.persistence.existingClaim | string | `""` | Mount an existing PVC instead of creating one. |
| backend.persistence.labels | object | `{}` | Labels for the created PVC. |
| backend.persistence.selector | object | `{}` | Selector for matching statically provisioned PVs. |
| backend.persistence.size | string | `"5Gi"` | Size of the created PVC. |
| backend.persistence.storageClassName | string | `nil` | StorageClass of the created PVC. Unset (null) uses the cluster default; "" requests no StorageClass. |
| backend.podSecurityContext | object | `{"fsGroup":1000}` | Pod-level security context for backend pods (fsGroup for volume ownership). |
| backend.replicaCount | int | `1` | Number of backend replicas. |
| backend.resources | object | `{}` | Resource requests and limits for the backend container. |
| backend.secret.existingName | string | `""` | Name of an existing Secret containing the backend JWT_SECRET and other backend-only secret variables. Required in production. |
| backend.secret.jwtSecretKey | string | `"JWT_SECRET"` | Secret key that holds the JWT secret. |
| backend.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000}` | Container-level security context for the backend. |
| backend.service.port | int | `8080` | Port exposed by the backend Service. |
| cnpg.cluster.database | string | `"kang"` | Application database name created in the CNPG Cluster. |
| cnpg.cluster.enabled | bool | `true` | Create a CloudNativePG PostgreSQL Cluster in the same release. Requires the operator to be running. |
| cnpg.cluster.imageName | string | `"ghcr.io/cloudnative-pg/postgresql:17.6"` | PostgreSQL image used by the CNPG Cluster. |
| cnpg.cluster.instances | int | `1` | Number of PostgreSQL instances in the CNPG Cluster. |
| cnpg.cluster.name | string | `""` | Override the generated CNPG Cluster name. |
| cnpg.cluster.owner | string | `"kang"` | Database owner role. |
| cnpg.cluster.resources | object | `{}` | Resource requests and limits for the CNPG Cluster pods. |
| cnpg.cluster.storage.size | string | `"10Gi"` | Size of the CNPG PostgreSQL data PVC. |
| cnpg.cluster.storage.storageClass | string | `""` | StorageClass for the CNPG PostgreSQL data PVC. Empty uses the cluster default. |
| cnpg.cluster.walStorage.enabled | bool | `false` | Mount a separate PVC for PostgreSQL WAL files. |
| cnpg.cluster.walStorage.size | string | `"2Gi"` | Size of the WAL PVC. |
| cnpg.cluster.walStorage.storageClass | string | `""` | StorageClass for the WAL PVC. Empty uses the cluster default. |
| cnpg.operator.enabled | bool | `true` | Install the CloudNativePG operator through the chart dependency. Requires cluster-scoped permissions. |
| frontend.env.API_URL | string | `""` | Server-to-server backend URL used by Next.js server components. Empty derives from the chart's networking values. |
| frontend.env.AUTH_COOKIE_NAME | string | `"kang_session"` | Session cookie name. Must match backend AUTH_COOKIE_NAME. |
| frontend.env.AUTH_REFRESH_COOKIE_NAME | string | `"kang_refresh"` | Refresh cookie name. Must match the backend's refresh cookie. |
| frontend.env.NEXT_PUBLIC_API_TIMEOUT_MS | string | `"10000"` | Browser API request timeout in milliseconds. |
| frontend.env.NEXT_PUBLIC_API_URL | string | `""` | Browser-facing backend API base URL. Empty derives from the chart's networking values. |
| frontend.env.NEXT_PUBLIC_APP_VERSION | string | `""` | Application version shown in the interface. |
| frontend.env.NEXT_PUBLIC_AUDIT_LOG_MAX_LIMIT | string | `"100"` | Maximum audit log page size requested by the browser. |
| frontend.env.NEXT_PUBLIC_ERROR_REPORTING_ENDPOINT | string | `""` | Optional browser error reporting endpoint. |
| frontend.env.NEXT_PUBLIC_FULL_MIGRATION_ENABLED | string | `"false"` | Show the full database migration UI. |
| frontend.env.NEXT_PUBLIC_KONG_DEVELOPER_DOCS_BASE_URL | string | `"https://developer.konghq.com"` | Base URL used for Kong developer documentation links. |
| frontend.env.NEXT_PUBLIC_KONG_OVERVIEW_REQUEST_TIMEOUT_MS | string | `"30000"` | Overview request timeout in milliseconds. |
| frontend.env.NEXT_PUBLIC_KONG_OVERVIEW_STALE_MS | string | `"30000"` | How long overview data stays fresh in milliseconds. |
| frontend.env.NEXT_PUBLIC_KONG_PROXY_TIMEOUT_MS | string | `"5000"` | Kong proxy request timeout in milliseconds. |
| frontend.env.NEXT_PUBLIC_KONG_STATUS_REFRESH_MS | string | `"10000"` | Gateway status refresh interval in milliseconds. |
| frontend.env.NEXT_PUBLIC_METRICS_REFRESH_MS | string | `"60000"` | Metrics refresh interval in milliseconds. |
| frontend.extraEnv | list | `[]` | Extra frontend environment entries as standard Kubernetes env items, including valueFrom Secret references. |
| frontend.extraEnvFrom | list | `[]` | Extra frontend envFrom references, such as a Secret with REVALIDATE_SECRET. |
| frontend.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| frontend.image.repository | string | `"ghcr.io/zaidanm16/kang-frontend"` | Frontend application image repository. |
| frontend.image.tag | string | `"v3.1.0"` | Frontend application image tag. Prefer immutable release or SHA tags. |
| frontend.replicaCount | int | `1` | Number of frontend replicas. |
| frontend.resources | object | `{}` | Resource requests and limits for the frontend container. |
| frontend.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"runAsGroup":1001,"runAsNonRoot":true,"runAsUser":1001}` | Container-level security context for the frontend. |
| frontend.service.port | int | `3000` | Port exposed by the frontend Service. |
| fullnameOverride | string | `""` | String to fully override the generated resource names. |
| global.commonLabels | object | `{}` | Labels added to all chart resources. |
| global.imagePullSecrets | list | `[]` | Names of existing image pull Secrets to attach to application pods. |
| global.podAnnotations | object | `{}` | Annotations added to frontend and backend pod templates. |
| metrics.enabled | bool | `false` | Deploy an in-chart single-node VictoriaMetrics instance. |
| metrics.existingSecret.key | string | `"PROMETHEUS_URL"` | Secret key that holds the metrics URL. |
| metrics.existingSecret.name | string | `""` | Secret holding the external metrics URL, for URLs that contain credentials. |
| metrics.externalUrl | string | `""` | Use an external Prometheus-compatible query URL instead of an in-chart instance. |
| metrics.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| metrics.image.repository | string | `"victoriametrics/victoria-metrics"` | VictoriaMetrics image repository. |
| metrics.image.tag | string | `"v1.137.0"` | VictoriaMetrics image tag. |
| metrics.persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes of the created PVC. |
| metrics.persistence.annotations | object | `{}` | Annotations for the created PVC. |
| metrics.persistence.enabled | bool | `true` | Create and mount a PVC for metrics storage. |
| metrics.persistence.existingClaim | string | `""` | Mount an existing PVC instead of creating one. |
| metrics.persistence.labels | object | `{}` | Labels for the created PVC. |
| metrics.persistence.selector | object | `{}` | Selector for matching statically provisioned PVs. |
| metrics.persistence.size | string | `"10Gi"` | Size of the created PVC. |
| metrics.persistence.storageClassName | string | `nil` | StorageClass of the created PVC. Unset (null) uses the cluster default. |
| metrics.resources | object | `{}` | Resource requests and limits for the VictoriaMetrics container. |
| metrics.retentionPeriod | string | `"1y"` | VictoriaMetrics retention period for stored time series. |
| metrics.scrapeConfig | string | `""` | Prometheus scrape configuration supplied to the in-chart VictoriaMetrics. Empty scrapes no targets. |
| metrics.service.port | int | `9090` | Port exposed by the in-chart metrics Service. |
| nameOverride | string | `""` | String to partially override the chart name used for resource naming. |
| networking.gatewayApi.allowedRoutesFrom | string | `"Same"` | AllowedRoutes from policy used only when this chart creates the Gateway. |
| networking.gatewayApi.allowedRoutesSelector | object | `{}` | Selector for AllowedRoutes when this chart creates the Gateway. |
| networking.gatewayApi.annotations | object | `{}` | Additional annotations for the created HTTPRoute or Gateway. |
| networking.gatewayApi.createGateway | bool | `false` | Create a Gateway in the release namespace instead of attaching to an existing Gateway. |
| networking.gatewayApi.gatewayClassName | string | `""` | GatewayClass name, required only when createGateway is true. |
| networking.gatewayApi.gatewayName | string | `""` | Name of the existing Gateway to attach the HTTPRoute to. |
| networking.gatewayApi.gatewayNamespace | string | `""` | Namespace of the existing Gateway. Empty uses the release namespace. |
| networking.gatewayApi.httpPort | int | `80` | HTTP listener port when this chart creates the Gateway. |
| networking.gatewayApi.sectionName | string | `""` | Existing Gateway listener name to attach to. |
| networking.gatewayApi.tls.enabled | bool | `false` | Enable a TLS listener when this chart creates the Gateway. |
| networking.gatewayApi.tls.port | int | `443` | HTTPS listener port when this chart creates the Gateway. |
| networking.gatewayApi.tls.secretName | string | `""` | Existing TLS Secret name for the Gateway listener. |
| networking.host | string | `""` | Public hostname used by Ingress and Gateway API modes. Also derives the default browser-facing API URL and CORS origin. |
| networking.ingress.annotations | object | `{}` | Additional annotations for the created Ingress. |
| networking.ingress.className | string | `""` | Ingress class name of an installed Ingress controller. The controller is not installed by this chart. |
| networking.ingress.tls.enabled | bool | `false` | Enable TLS on the created Ingress. The referenced Secret must exist in the release namespace. |
| networking.ingress.tls.secretName | string | `""` | Existing TLS Secret name for the Ingress. |
| networking.mode | string | `"none"` | Exposure mode: none (local port-forward), ingress, or gatewayApi. |
| networking.publicApiUrl | string | `""` | Explicit browser-facing API base URL, for custom public API origins. |
| nodeSelector | object | `{}` | Node selector applied to application pods. |
| redis.args | list | `["--bind=0.0.0.0","--port=6379"]` | Command arguments for the DragonflyDB container. |
| redis.enabled | bool | `false` | Deploy an in-chart DragonflyDB (Redis-compatible) instance. |
| redis.existingSecret.key | string | `"RATE_LIMIT_REDIS_URL"` | Secret key that holds the Redis URL. |
| redis.existingSecret.name | string | `""` | Secret holding the external Redis/DragonflyDB URL, for URLs that contain credentials. |
| redis.externalUrl | string | `""` | Use an external Redis/DragonflyDB URL instead of an in-chart instance. |
| redis.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| redis.image.repository | string | `"docker.dragonflydb.io/dragonflydb/dragonfly"` | DragonflyDB image repository. |
| redis.image.tag | string | `"v1.37.0"` | DragonflyDB image tag. |
| redis.persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes of the created PVC. |
| redis.persistence.annotations | object | `{}` | Annotations for the created PVC. |
| redis.persistence.enabled | bool | `false` | Create and mount a PVC for DragonflyDB snapshot files. |
| redis.persistence.existingClaim | string | `""` | Mount an existing PVC instead of creating one. |
| redis.persistence.labels | object | `{}` | Labels for the created PVC. |
| redis.persistence.selector | object | `{}` | Selector for matching statically provisioned PVs. |
| redis.persistence.size | string | `"5Gi"` | Size of the created PVC. |
| redis.persistence.storageClassName | string | `nil` | StorageClass of the created PVC. Unset (null) uses the cluster default. |
| redis.resources | object | `{}` | Resource requests and limits for the DragonflyDB container. |
| redis.service.port | int | `6379` | Port exposed by the in-chart Redis-compatible Service. |
| serviceAccount.annotations | object | `{}` | Annotations for the created ServiceAccount. |
| serviceAccount.create | bool | `true` | Create a shared ServiceAccount for application pods. Token automount is disabled. |
| serviceAccount.name | string | `""` | Override the generated ServiceAccount name. |
| tolerations | list | `[]` | Tolerations applied to application pods. |

## Operational notes

- `backend.secret.existingName` references the backend Secret. Its `JWT_SECRET` key (overridable via `backend.secret.jwtSecretKey`) is required in production. The same Secret may contain other backend-only secret variables such as `KANG_LICENSE`, `KANG_LICENSE_PUBLIC_KEYS`, `CLOUDINARY_API_SECRET`, `KONG_CREDENTIAL_ENCRYPTION_KEY`, `MIGRATION_WORKER_TOKEN`, or OTLP credentials; Secret keys are exposed as environment variables through `envFrom`. Create it through your platform's secret manager, External Secrets, Sealed Secrets, or `kubectl create secret`. Do not put secret values in a committed values file; Helm values are stored with the release.
- The frontend image writes `NEXT_PUBLIC_*` runtime settings to `/app/public/runtime-env.js` at container startup. These values are browser-visible configuration, never credentials. `API_URL` is the server-to-server backend URL; `NEXT_PUBLIC_API_URL` is the browser-facing base API URL. With one public hostname and the supplied routing templates, the browser-facing URL should be that origin, while `API_URL` remains the in-cluster backend Service URL. Frontend cookie names must match the backend's `AUTH_COOKIE_NAME` and `AUTH_REFRESH_COOKIE_NAME`.
- `storageClassName` semantics: `null` (default) omits the field and lets the cluster's default StorageClass apply; a class name requests that StorageClass; `""` explicitly requests no StorageClass, for a matching pre-created or static PV. A PVC selector constrains static PV matching only.
- Backend SQLite, local Dragonfly, and local VictoriaMetrics are single-replica deployments; the chart uses `Recreate` for those stateful singletons. With `RATE_LIMIT_STORE=memory` (the default when Redis is off), each backend replica keeps its own in-memory rate-limit state.
- The backend image workflow builds only the API binary and the frontend workflow builds the standalone Next.js app. There is no published migration-worker image; if you use the full database migration features, build and operate `Dockerfile.migration-worker` separately, then set the worker URL and token via `backend.extraEnv` and a Secret.
- Health endpoints: backend `/health`, frontend `/api/health`. Kubernetes probes use those paths.
- Scheduling: `nodeSelector`, `tolerations`, and `affinity` apply to application pods; `global.podAnnotations`, `global.commonLabels`, and `global.imagePullSecrets` apply chart-wide. The shared ServiceAccount does not automount Kubernetes API credentials.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Backend CrashLoopBackOff | `JWT_SECRET` exists in the referenced Secret; inspect `kubectl logs deploy/kang-backend`. For PostgreSQL/MySQL, check `DB_DRIVER`, Secret key and DSN. |
| SQLite permission/open error | Verify PVC binding and mounted volume ownership; check storage driver mount permissions for UID/GID 1000. |
| PVC Pending | Check StorageClasses and PV matching: `kubectl get pvc,pv,storageclass -n kang`. `storageClassName: ""` disables dynamic provisioning. |
| Browser API calls fail | Check frontend `NEXT_PUBLIC_API_URL`, browser reachability, route path matches, CORS origin and cookie settings. Internal Service DNS is not reachable from a user's browser. |
| Login cookie is not stored | Match cookie names; set `AUTH_COOKIE_SECURE=true` only when requests use HTTPS, and confirm proxy TLS termination behavior. |
| HTTPRoute not accepted | Inspect `kubectl describe httproute -n kang` and Gateway listener `allowedRoutes`; confirm API/controller support and parent listener section. |
| CNPG Cluster not ready | Confirm operator is running, `Cluster` CRD exists, PVCs bind, and the selected PostgreSQL image is supported by that operator. |
| Dashboard has no metrics | Confirm backend `PROMETHEUS_URL` points to a reachable Prometheus-compatible query API and the metrics service has data. |
| Dragonfly not used | Confirm `RATE_LIMIT_STORE=redis`, Redis URL Secret/value, and Dragonfly Service readiness. |

## License

The Kang chart is available under the [MIT License](LICENSE). Its bundled CloudNativePG dependency is licensed separately under Apache-2.0; see [third-party notices](THIRD_PARTY_NOTICES.md) and [the Apache license text](licenses/Apache-2.0.txt). The Kang frontend and backend are separate projects with their own licenses.

----------------------------------------------

Autogenerated values table from chart metadata using [helm-docs](https://github.com/norwoodj/helm-docs).
