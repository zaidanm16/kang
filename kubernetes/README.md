# Kubernetes manifest deployment

`kang.yaml` deploys the KANG frontend, backend, and a single PostgreSQL StatefulSet with a 10Gi persistent volume claim. Services are internal ClusterIP Services; PostgreSQL uses a headless Service. Kong Gateway is managed separately.

## Requirements

Use a Kubernetes cluster with a default StorageClass, or set `storageClassName` in the PostgreSQL `volumeClaimTemplates` to an available class. The manifest uses the published images `ghcr.io/zaidanm16/kang-frontend:v3.0.0` and `ghcr.io/zaidanm16/kang-backend:v1.0.0`.

## Configure and apply

Generate independent JWT and database secrets with `openssl rand -hex 32`. Edit `kang.yaml`:

- Replace the JWT placeholder in `kang-backend-secrets`.
- Set matching database passwords in `POSTGRES_PASSWORD` and the `postgresql://...` value of `DATABASE_DSN`. Hexadecimal passwords can be used directly in the URI; other passwords may need percent encoding in the URI.

From the repository root:

```sh
kubectl apply -f kubernetes/kang.yaml
kubectl get pods,pvc,svc
```

Resources are created in the current namespace. Keep the edited manifest containing secrets out of version control, or manage the Secret separately and remove its document before applying the rest.

Use two terminals for local access:

```sh
kubectl port-forward svc/kang-backend 8080:8080
kubectl port-forward svc/kang-frontend 3000:3000
```

Open http://localhost:3000. PostgreSQL initializes independently; the backend may restart until the database is available. Health endpoints are `/health` on the backend and `/api/health` on the frontend.

## Public access and configuration

For public access, create the routing resources required by your cluster and update `NEXT_PUBLIC_API_URL` to the browser-facing API origin and `CORS_ORIGINS` to the frontend origin. Set `AUTH_COOKIE_SECURE=true` for HTTPS. The frontend's `API_URL` remains the internal backend Service URL. Restart the app Deployments after changing ConfigMaps or Secrets.

For an existing PostgreSQL database, update `DATABASE_DSN` and omit the bundled PostgreSQL Service and StatefulSet. Redis and a Prometheus-compatible metrics API can be configured through backend environment settings; they are not included in the manifest. Additional settings are documented in the [backend environment example](https://github.com/zaidanm16/kang-backend/blob/main/.env.example).

For a new installation, add a separate stable `KONG_CREDENTIAL_ENCRYPTION_KEY` to your backend Secret and reference it with `valueFrom.secretKeyRef` in the backend container's `env` list. The standalone manifest does not automatically expose every extra Secret key. If migrating an existing database, preserve the effective source key instead of generating a replacement. See [database migration and coordinated key rotation](https://zaidanm16.github.io/kang/guides/operations/).

For UI-managed licenses, add `KANG_LICENSE_PUBLIC_KEYS` to the Secret and reference it in the backend environment. Do not configure `KANG_LICENSE`; a global administrator installs the signed token through **System → Kang License**. Never deploy the issuer's private signing key. See [license management](https://zaidanm16.github.io/kang/guides/plans/).

## Data and updates

PostgreSQL stores data in the `data-kang-postgres-0` PVC. Back up with `pg_dump` before upgrades or database changes. StatefulSet deletion normally retains its claims; inspect PVCs and the storage reclaim policy before deleting data. This single PostgreSQL instance has no automated failover or backup configuration.

Pin image tags in the manifest before updates, then apply it again. Inspect failures with:

```sh
kubectl logs deploy/kang-backend
kubectl logs deploy/kang-frontend
kubectl logs statefulset/kang-postgres
kubectl describe pvc data-kang-postgres-0
```
