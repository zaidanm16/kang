# KANG Deploy

[![Release](https://img.shields.io/badge/release-v3.0.0-blue)](https://github.com/zaidanm16/kang-deploy/releases)
[![Release workflow](https://github.com/zaidanm16/kang-deploy/actions/workflows/release.yaml/badge.svg)](https://github.com/zaidanm16/kang-deploy/actions/workflows/release.yaml)

Deploy [Kang](https://github.com/zaidanm16/kang-frontend), a management application for Kong API Gateway, with Docker Compose or Kubernetes. Kong Gateway runs separately.

## Getting started

The quickest way to try Kang is with **Docker Compose**. You need Docker with the Compose plugin, `git`, and `openssl`.

```sh
git clone --depth 1 --branch v3.0.0 https://github.com/zaidanm16/kang-deploy.git
cd kang-deploy/compose
cp backend.env.example backend.env
(umask 077; printf 'JWT_SECRET=%s\nPOSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 32)" "$(openssl rand -hex 32)" > .env)
docker compose up -d
```

If the repository or images are private, authenticate Git and Docker with an account that has access before starting.

Open **http://localhost:3000**. Get the one-time setup token with `docker compose logs backend`, then follow the setup screen to create your administrator and connect an existing Kong Admin API. The Admin API must be reachable from the backend container; `localhost` inside a container refers to that container.

This starts the frontend, backend, and PostgreSQL with persistent storage. Kang starts on the Free plan; no license key is required. To stop it, run `docker compose down` from the same directory. Your database is retained.

For public URLs, HTTPS, external services, and updates, see the [Compose guide](compose/README.md).

## Kubernetes

Use the **published Helm chart** with an existing Kubernetes cluster and a default StorageClass. The default chart also installs the CloudNativePG operator, which requires cluster-scoped permissions.

```sh
kubectl create namespace kang
secret_file="$(mktemp)"
openssl rand -hex 32 > "$secret_file"
kubectl -n kang create secret generic kang-backend-secrets \
  --from-file=JWT_SECRET="$secret_file"
rm -f "$secret_file"

helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.0.0 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  --set backend.env.AUTH_COOKIE_SECURE=false
```

For local access, run these in separate terminals, then open http://localhost:3000:

```sh
kubectl -n kang port-forward svc/kang-backend 8080:8080
kubectl -n kang port-forward svc/kang-frontend 3000:3000
```

See the [chart guide](chart/kang/README.md) for external databases, storage, HTTPS, Ingress, Gateway API, and custom values. A [standalone Kubernetes manifest](kubernetes/README.md) is also available.

## Releases

Release **v3.0.0** includes the chart and frontend version `3.0.0`. Backend images are pinned independently; the current default is `ghcr.io/zaidanm16/kang-backend:v1.0.0`.

The [release workflow](.github/workflows/release.yaml) publishes these artifacts when a matching `v*` tag is pushed:

| Artifact | Use |
| --- | --- |
| `oci://ghcr.io/zaidanm16/kang:3.0.0` | Install with Helm using `--version 3.0.0` |
| `oci://ghcr.io/zaidanm16/kang:v3.0.0` | Alias for the same chart artifact |
| `kang-3.0.0.tgz` | Packaged chart with its pinned CloudNativePG dependency |
| `kang-compose.tar.gz` | Docker Compose stack, environment examples, and guide |
| `kang.yaml`, `kubernetes-README.md` | Standalone Kubernetes deployment |
| `SHA256SUMS` | Checksums for the downloadable files |

Chart `version` must match the release tag without `v`. `appVersion` records the frontend version. Application image tags retain the upstream `v` prefix. The `v3.0.0` OCI tag is an alias of the standard Helm tag `3.0.0`; Helm installation examples use `--version 3.0.0`. GitHub lists OCI Helm charts under container Packages because they use the same registry format. Registry packages must be public for anonymous downloads; private packages require registry authentication.

The release badge uses an explicit version so it also works while this repository is private. Update it alongside the documented release version.

## Contributing

Application source code lives in [kang-frontend](https://github.com/zaidanm16/kang-frontend) and [kang-backend](https://github.com/zaidanm16/kang-backend). This repository contains deployment configuration; chart sources live in `chart/kang`.

Validate source changes before publishing:

```sh
helm dependency build ./chart/kang
helm lint ./chart/kang --set backend.secret.existingName=validation-secret
helm template kang ./chart/kang --set backend.secret.existingName=validation-secret
JWT_SECRET=validation-only POSTGRES_PASSWORD=validation-only \
  docker compose -f compose/compose.yaml --env-file compose/.env.example \
  config --no-env-resolution --quiet
```

Update `chart/kang/Chart.yaml` and the documented release version together, commit and push, then create the matching tag. The workflow packages the artifacts, pushes the OCI chart, and creates the GitHub Release:

```sh
git tag v3.0.0
git push origin v3.0.0
```

Never commit credentials, signing keys, signed license keys, or local environment files. Rendering validates generated configuration; runtime deployment also depends on storage, controllers, and network reachability.

## License

Copyright © 2026 Muhammad Zaidan. All rights reserved. This repository is proprietary; use and redistribution require written permission as described in [LICENSE](LICENSE). Bundled third-party components retain their own licenses.
