# Deploy KANG on Kubernetes

This Helm chart deploys the KANG frontend and backend with PostgreSQL through CloudNativePG by default, plus optional cache, metrics, and networking resources.

KANG is the management application for Kong Gateway. It does not deploy Kong Gateway itself.

## What runs

| Component | Default | Image / behavior |
| --- | --- | --- |
| Frontend | Enabled | `ghcr.io/zaidanm16/kang-frontend:v3.0.0`; Next.js standalone runtime, port 3000 |
| Backend | Enabled | `ghcr.io/zaidanm16/kang-backend:v1.0.0`; Go API, port 8080 |
| Application database | PostgreSQL | CloudNativePG cluster with persistent storage |
| PostgreSQL | Enabled | CloudNativePG `Cluster`; can instead connect to PostgreSQL/MySQL using a Secret-provided DSN |
| Redis-compatible cache | Disabled | Optional DragonflyDB; can instead supply a Redis URL or Secret |
| Metrics query store | Disabled | Optional single-node VictoriaMetrics; can instead supply a Prometheus-compatible URL or Secret |
| Migration worker | Not deployed | The backend has optional migration-worker integration, but neither repo's image workflow publishes a worker image. Deploy/build it separately and set the backend URL and token through extra environment/Secret references. |

Frontend/backend image names and the `v`-prefixed release tags match the repositories' GitHub Actions workflows. Override each image repository and tag when mirroring images or selecting another release. The CNPG operator and Dragonfly/VictoriaMetrics are separate upstream images/charts, not KANG application images.

## Requirements

- A Kubernetes cluster and `kubectl` with namespace permissions.
- Helm 3.19 or Helm 4 for the chart. The checked-in CNPG dependency is pinned to chart `0.22.0`.
- A default StorageClass, or a storage class / pre-created PV and claim that matches your values, when persistence is enabled.
- For `networking.mode: ingress`, an installed Ingress controller.
- For `networking.mode: gatewayApi`, Gateway API CRDs and a controller that implements `Gateway` and `HTTPRoute` `gateway.networking.k8s.io/v1`.
- For a private GHCR package, an image pull Secret and its name in `global.imagePullSecrets`. The application image references are public workflow outputs when package visibility permits anonymous pulls.
- A Kubernetes Secret containing a unique, stable `JWT_SECRET` value. For an existing PostgreSQL/MySQL DB, also provide a Secret key with its DSN.

The CNPG dependency can install the operator when `cnpg.operator.enabled=true`. This needs cluster-scoped permissions. Set `cnpg.cluster.enabled=true` to create the app database cluster in the same Helm release. The CNPG operator must be available and its CRDs established before a `Cluster` resource can be reconciled. If your cluster policy separates operator administration, install/manage the operator separately and set `cnpg.operator.enabled=false`.

## Quick start: Helm with PostgreSQL

Install the published OCI chart at `oci://ghcr.io/zaidanm16/kang`; cloning this repository is not required. The `v3.0.0` tag is also published as an alias; use `--version 3.0.0` with Helm. For a private chart, authenticate first with `helm registry login ghcr.io` using a token with package read access.

Create a namespace and a Secret outside Helm. Keeping credentials outside Helm values avoids writing them into a values file or the Helm release record.

```sh
kubectl create namespace kang
secret_file="$(mktemp)"
trap 'rm -f "$secret_file"' EXIT
openssl rand -hex 32 > "$secret_file"
kubectl -n kang create secret generic kang-backend-secrets \
  --from-file=JWT_SECRET="$secret_file"

helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.0.0 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  --set backend.env.AUTH_COOKIE_SECURE=false
```

The defaults install the CNPG operator and a PostgreSQL cluster with persistent storage. This requires cluster-scoped permissions and CNPG CRDs. The chart leaves `storageClassName` unset (`null`) so Kubernetes can use its default StorageClass. To access locally without an Ingress/Gateway, use two terminals:

```sh
kubectl -n kang port-forward svc/kang-backend 8080:8080
kubectl -n kang port-forward svc/kang-frontend 3000:3000
```

Open `http://localhost:3000`. The default browser API URL is `http://localhost:8080`, and the backend CORS origin is `http://localhost:3000`. When exposing the application publicly, set a public hostname and TLS as described below; do not leave `AUTH_COOKIE_SECURE=false` for HTTPS production traffic. For a non-TLS Ingress/Gateway test, set it to `false`; keep it `true` on HTTPS.

The default storage values and both app image tags are in `values.yaml`. Use a reviewed values file for repeatable installs rather than long command-line overrides.

## Values and supported modes

### Images and replicas

```yaml
backend:
  image:
    repository: ghcr.io/zaidanm16/kang-backend
    tag: v1.0.0
    pullPolicy: IfNotPresent
  replicaCount: 1

frontend:
  image:
    repository: ghcr.io/zaidanm16/kang-frontend
    tag: v3.0.0
    pullPolicy: IfNotPresent
```

The workflow publishes `main`, `sha-<commit>`, `latest` on a release, and semver tags such as `v3.0.0` and `v3.0`. Prefer immutable release or SHA tags for controlled deployments. Set `pullPolicy: Always` for mutable tags when you deliberately want the kubelet to re-check the registry. If GHCR requires authentication in your cluster:

```yaml
global:
  imagePullSecrets:
    - name: ghcr-pull-secret
```

Create that Secret in the release namespace using your registry credentials. Never put a registry token in this chart's values or commit it.

### Application Secret and environment

`backend.secret.existingName` references the backend Secret. Its `JWT_SECRET` key (overridable using `backend.secret.jwtSecretKey`) is required in production. The same Secret may contain other backend-only secret variables such as `KANG_LICENSE`, `KANG_LICENSE_PUBLIC_KEYS`, `CLOUDINARY_API_SECRET`, `KONG_CREDENTIAL_ENCRYPTION_KEY`, `MIGRATION_WORKER_TOKEN`, or OTLP credentials; Secret keys are exposed as environment variables through `envFrom`.

Create it through your platform's secret manager, External Secrets, Sealed Secrets, or `kubectl create secret`. Do not put secret values in a committed values file. Helm values are stored with the release, and rendered Secret manifests are not a secret-management solution.

Non-sensitive backend variables read by `backend/internal/config/config.go` can be set under `backend.env`. The chart has defaults for the main auth, CORS, DB pool, metrics, rate limit, cache, tracing, and retention settings. `backend.extraEnv` accepts standard Kubernetes `env` entries (including `valueFrom.secretKeyRef`); `backend.extraEnvFrom` accepts `envFrom` references. Use these for secret-backed or less-common settings without exposing them in ConfigMaps. Frontend runtime values such as `API_URL`, cookie names, and `NEXT_PUBLIC_*` settings from `frontend/.env.example` are available under `frontend.env`. `INTERNAL_API_URL` and `REVALIDATE_SECRET` are server-only values and can be set via `frontend.extraEnv` or `frontend.extraEnvFrom` Secret references. `RUNTIME_ENV_FILE` and `NODE_ENV` are managed by the image/chart.

The frontend image writes `NEXT_PUBLIC_*` runtime settings to `/app/public/runtime-env.js` at container startup. These values are browser-visible configuration, never credentials. `API_URL` is the server-to-server backend URL; `NEXT_PUBLIC_API_URL` is the browser-facing base API URL. With one public hostname and the supplied routing templates, the browser-facing URL should be that origin (for example `https://kang.example.com`), while `API_URL` remains the in-cluster backend Service URL.

The frontend cookie names must match the backend's `AUTH_COOKIE_NAME` and `AUTH_REFRESH_COOKIE_NAME`. Defaults are `kang_session` and `kang_refresh`.

### Database choices

The backend supports the `sqlite`, `postgres`, and `mysql` drivers.

| Mode | Values | Storage / scaling |
| --- | --- | --- |
| SQLite (optional) | Disable `cnpg.cluster.enabled` and `cnpg.operator.enabled`, set `backend.database.driver: sqlite` and `backend.database.dsn: /data/data.db` | Keep backend at one replica. PVC recommended; `emptyDir` is possible but loses DB data when the pod is replaced. |
| External PostgreSQL | `backend.database.driver: postgres`; set `backend.database.dsnSecret.name/key` | DSN is read from an existing Secret. Set backend replicas according to your DB capacity and rollout strategy. |
| External MySQL | `backend.database.driver: mysql`; set `backend.database.dsnSecret.name/key` | Same Secret approach; DSN syntax is defined by the backend's MySQL driver. |
| CNPG managed PostgreSQL (default) | `cnpg.cluster.enabled: true` and `cnpg.operator.enabled: true` (unless the operator is already managed elsewhere) | CNPG creates its own PVCs and `<cluster>-app` Secret; backend reads the `uri` key. Configure storage on `cnpg.cluster.storage`. |

For external PostgreSQL/MySQL, disable both `cnpg.cluster.enabled` and `cnpg.operator.enabled`. External PostgreSQL example (Secret value: `postgresql://kang:PASSWORD@postgres.example.internal:5432/kang?sslmode=require`):

```sh
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
  replicaCount: 2
```

CNPG example for a new installation:

```yaml
backend:
  replicaCount: 2
  persistence:
    enabled: false
cnpg:
  operator:
    enabled: true
  cluster:
    enabled: true
    instances: 3
    database: kang
    owner: kang
    imageName: ghcr.io/cloudnative-pg/postgresql:17.6
    storage:
      size: 20Gi
      storageClass: fast-rwo
```

CNPG's `Cluster` creates PostgreSQL storage. Its generated `uri` DSN is injected into the backend as a Secret reference; the password is not rendered in the KANG ConfigMap. `instances` and the CNPG cluster image are separately configurable. Coordinate PostgreSQL major version upgrades with CNPG's supported upgrade procedure; changing `imageName` is not a database major-upgrade plan.

The backend performs migrations when `MIGRATE_ON_START=true` (default). With multiple backend replicas, coordinate startup/rollout and database migrations for your deployment. Do not assume Helm manages application data migration or SQLite-to-PostgreSQL data transfer.

### PVC, PV and StorageClass behavior

Backend SQLite, local Dragonfly, and local VictoriaMetrics each support:

- `persistence.enabled`: create/mount a PVC or use ephemeral `emptyDir` when false.
- `persistence.existingClaim`: mount an existing PVC instead of creating one.
- `persistence.size`, `accessModes`, and `storageClassName` when the chart creates a claim.
- Backend PVC `annotations`, `labels`, and `selector` for matching statically provisioned PVs.

For `storageClassName`:

- `null` (default): omit the field and let the cluster's default StorageClass apply, if configured.
- A class name: request that StorageClass.
- `""`: explicitly request no StorageClass; this is for a matching pre-created/static PV, not dynamic provisioning.

A PVC selector can constrain static PV matching; selectors do not dynamically provision storage. Access modes are binding/mount capabilities, not a general guarantee that the filesystem supports concurrent writers. SQLite remains single-writer and should use one backend replica even on shared storage. Local Dragonfly and VictoriaMetrics are single-replica deployments; the chart uses `Recreate` for those stateful singletons. PVC retention, reclaim policy, snapshots and backups depend on the StorageClass, CSI driver and cluster policy. The chart does not configure a backup target for these PVCs.

When using `existingClaim`, the claim must be in the same namespace as the pod and have compatible capacity, access mode, selector and volume topology. For external DB mode the backend database PVC is not mounted. CNPG manages its own claims and does not use the app's SQLite PVC values.

### Redis / Dragonfly

No Redis service is required by default: rate limiting uses the backend's in-memory store. Enable a Dragonfly instance in the chart:

```yaml
redis:
  enabled: true
  persistence:
    enabled: true
    size: 5Gi
backend:
  env:
    RATE_LIMIT_STORE: "" # empty means auto-select Redis when configured
```

The chart sets the in-cluster `RATE_LIMIT_REDIS_URL` and selects Redis-backed rate limiting when a local or external Redis URL is configured. Local Dragonfly is a single Deployment, with snapshot files on its optional `/data` PVC; it is not a Redis HA/failover cluster and the PVC is not a backup.

Use an external URL without credentials directly:

```yaml
redis:
  externalUrl: redis://redis.example.internal:6379/0
```

For authenticated URLs, keep the full URL in a Kubernetes Secret instead:

```sh
kubectl -n kang create secret generic kang-redis \
  --from-file=RATE_LIMIT_REDIS_URL=/secure/path/to/redis-url
```

```yaml
redis:
  existingSecret:
    name: kang-redis
    key: RATE_LIMIT_REDIS_URL
```

The backend can also use this URL for cache integrations that fall back to `RATE_LIMIT_REDIS_URL`. Set dedicated cache URL variables through `backend.extraEnv` when those integrations need separate Redis services or credentials.

### VictoriaMetrics / external metrics

The dashboard's backend queries a Prometheus-compatible API at `PROMETHEUS_URL`. With metrics disabled and no external URL/Secret configured, the backend's own fallback is `http://prometheus:9090`; this chart does not create a Service at that address, so configure an external endpoint or enable local VictoriaMetrics if dashboard metrics are needed. To turn on a local single-node VictoriaMetrics instance:

```yaml
metrics:
  enabled: true
  persistence:
    enabled: true
    size: 20Gi
```

The chart configures the backend to use the internal VictoriaMetrics Service. `metrics.scrapeConfig` supplies a Prometheus scrape configuration to that single-node instance; by default it scrapes no external targets. This chart does not discover Kong Gateway metrics endpoints automatically. Add scrape jobs only for endpoints that are reachable and actually expose Prometheus metrics.

For an existing Prometheus/VictoriaMetrics service, use `metrics.externalUrl`. If its URL contains credentials, use `metrics.existingSecret` with a Secret key named `PROMETHEUS_URL` instead. Do not enable both an external Secret URL and a local metrics URL. Metrics storage is independent of the backend DB, and persistence is optional.

### Ingress and Gateway API

Choose one exposure mode. Both templates route `/api/v1`, `/auth`, and `/health` to the backend and all remaining paths to the frontend. This keeps browser API calls on the same origin and avoids adding a second public host/CORS setup.

#### Existing Ingress controller

```yaml
networking:
  mode: ingress
  host: kang.example.com
  ingress:
    className: nginx
    annotations: {}
    tls:
      enabled: true
      secretName: kang-example-tls
backend:
  env:
    AUTH_COOKIE_SECURE: "true"
```

The chart creates an `Ingress` (`networking.k8s.io/v1`) and expects the TLS Secret in the release namespace. The Ingress controller itself is not installed by this chart. Controller-specific annotations are passed through `networking.ingress.annotations`.

#### Existing Gateway API Gateway

```yaml
networking:
  mode: gatewayApi
  host: kang.example.com
  gatewayApi:
    createGateway: false
    gatewayName: shared-gateway
    gatewayNamespace: edge
    sectionName: https
    allowedRoutesFrom: All
    tls:
      enabled: true
backend:
  env:
    AUTH_COOKIE_SECURE: "true"
```

This creates an `HTTPRoute` attached to an existing `Gateway`. The Gateway's listener must accept Routes from this namespace; `allowedRoutesFrom` configures that policy only when this chart creates the Gateway. The referenced `sectionName` should match the existing listener name. Gateway API CRDs/controller are not installed by this chart.

To create a Gateway in the release namespace instead, set `createGateway: true`, provide `gatewayClassName`, and provide `tls.secretName` if TLS is enabled. TLS certificate Secrets must be in the Gateway's namespace. The chart does not create certificates or controllers.

The route API is `gateway.networking.k8s.io/v1`. Ensure the installed Gateway API version and controller support `Gateway` and `HTTPRoute` at this version. If your controller requires extra policy/annotations or cross-namespace grants, create those resources according to that controller's documentation; this chart intentionally does not guess controller-specific settings.

For custom public API origins, set `networking.publicApiUrl` to the browser-facing API base and set `backend.env.CORS_ORIGINS` to the exact frontend origin(s), comma-separated. CORS origins are origins (scheme + host + optional port), not paths. With the supplied same-host routes, the chart derives CORS from `networking.host`; an explicit `backend.env.CORS_ORIGINS` overrides that value.

### Scheduling, labels and pull secrets

- `global.podAnnotations` adds annotations to frontend/backend pod templates.
- `global.commonLabels` adds labels to chart resources.
- `global.imagePullSecrets` attaches image pull secrets to app pods.
- `nodeSelector`, `tolerations`, and `affinity` are available for both app pods.
- `serviceAccount.create` controls the shared ServiceAccount. KANG pods do not need Kubernetes API credentials, and token automount is disabled.
- `backend.resources`, `frontend.resources`, `redis.resources`, `metrics.resources`, and `cnpg.cluster.resources` accept standard Kubernetes resource requests/limits.

## Install with a values file

Create `kang-values.yaml` outside the repository or in a private deployment repository, then install:

```sh
helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.0.0 \
  --namespace kang --create-namespace \
  -f kang-values.yaml \
  --set backend.secret.existingName=kang-backend-secrets
```

Render before applying and review the manifests for your cluster:

```sh
helm template kang oci://ghcr.io/zaidanm16/kang \
  --version 3.0.0 \
  --namespace kang \
  -f kang-values.yaml \
  --set backend.secret.existingName=kang-backend-secrets
```

`values.schema.json` validates supported enums and common value types. Do not place credentials or signed license values on shell command lines where they can be recorded in shell history or process listings.

## Upgrade and operational notes

Pin app images to a release or commit tag and update both image tags through reviewed values. Kubernetes rolls the Deployments; Helm does not back up SQLite/CNPG data or perform cross-engine data migration. Before upgrading backend schema or database engine, follow the backend migration and backup guidance.

The backend image workflow builds only `Dockerfile.prod` (the API binary). The frontend workflow builds `Dockerfile.prod` (the standalone Next.js app). There is no published KANG migration-worker image in those workflows. Do not configure a guessed worker image; if using full database migration features, separately build and operate `Dockerfile.migration-worker`, then set the worker URL/token via `backend.extraEnv` and a Secret. The migration worker data volume and allowed-host policy are the operator's responsibility.

With `RATE_LIMIT_STORE=memory` (the default when Redis is off), each backend replica keeps its own in-memory rate-limit state. For multi-replica deployments that need a shared rate-limit store, configure local Dragonfly or an external Redis URL/Secret.

The backend exposes `/health`; the frontend exposes `/api/health`. The Helm probes use those paths. Kubernetes Service resources are `ClusterIP`; exposure is handled by Ingress or Gateway API. There is no NodePort or LoadBalancer setting in this chart.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Backend CrashLoopBackOff | `JWT_SECRET` exists in the referenced Secret; inspect `kubectl logs deploy/kang-backend`. For PostgreSQL/MySQL, check `DB_DRIVER`, Secret key and DSN. |
| SQLite permission/open error | Verify PVC binding and mounted volume ownership; check storage driver mount permissions for UID/GID 1000. |
| PVC Pending | Check StorageClasses and PV matching: `kubectl get pvc,pv,storageclass -n kang`. `storageClassName: ""` disables dynamic provisioning. |
| Browser API calls fail | Check frontend `NEXT_PUBLIC_API_URL`, browser reachability, route path matches, CORS origin and cookie settings. Internal Service DNS is not reachable from a user's browser. |
| Login cookie is not stored | Match cookie names; set `AUTH_COOKIE_SECURE=true` only when requests use HTTPS, and confirm proxy TLS termination / forwarded protocol behavior. |
| HTTPRoute not accepted | Inspect `kubectl describe httproute -n kang` and Gateway listener `allowedRoutes`; confirm API/controller support and parent listener section. |
| CNPG Cluster not ready | Confirm operator is running, `Cluster` CRD exists, PVCs bind, and the selected PostgreSQL image is supported by that operator. |
| Dashboard has no metrics | Confirm backend `PROMETHEUS_URL` points to a reachable Prometheus-compatible query API and the metrics service has data. Local VictoriaMetrics starts with no external scrape jobs by default. If no endpoint is configured, the backend falls back to its own default `http://prometheus:9090`. |
| Dragonfly not used | Confirm `RATE_LIMIT_STORE=redis`, Redis URL Secret/value, and Dragonfly Service readiness. |

Useful commands:

```sh
kubectl get deploy,svc,pod,pvc -n kang
kubectl logs -n kang deploy/kang-backend
kubectl logs -n kang deploy/kang-frontend
kubectl describe httproute -n kang
kubectl get cluster.postgresql.cnpg.io -n kang
```

## Implementation references

- [Backend README](https://github.com/zaidanm16/kang-backend/blob/main/README.md)
- [Backend environment example](https://github.com/zaidanm16/kang-backend/blob/main/.env.example)
- [Backend licensing deployment notes](https://github.com/zaidanm16/kang-backend/blob/main/docs/licensing.md)
- [Frontend README](https://github.com/zaidanm16/kang-frontend/blob/main/README.md)
- [Frontend environment example](https://github.com/zaidanm16/kang-frontend/blob/main/.env.example)
- [Frontend runtime entrypoint](https://github.com/zaidanm16/kang-frontend/blob/main/scripts/docker-entrypoint.sh)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Helm chart best practices](https://helm.sh/docs/chart_best_practices/)
- [CloudNativePG](https://cloudnative-pg.io/documentation/)

## License

The Kang chart is available under the [MIT License](LICENSE). Its bundled CloudNativePG dependency is licensed separately under Apache-2.0; see [third-party notices](THIRD_PARTY_NOTICES.md) and [the Apache license text](licenses/Apache-2.0.txt). The Kang frontend and backend are separate projects with their own licenses.
