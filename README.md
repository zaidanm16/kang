# KANG Deploy

[![Release](https://img.shields.io/github/v/release/zaidanm16/kang-deploy)](https://github.com/zaidanm16/kang-deploy/releases)
[![Release workflow](https://github.com/zaidanm16/kang-deploy/actions/workflows/release.yaml/badge.svg)](https://github.com/zaidanm16/kang-deploy/actions/workflows/release.yaml)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?logo=helm&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?logo=docker&logoColor=white)
![License](https://img.shields.io/badge/License-Proprietary-lightgrey)

KANG is a management application for Kong API Gateway. This repository contains deployment configuration and installation instructions. Application source code lives in [kang-frontend](https://github.com/zaidanm16/kang-frontend) and [kang-backend](https://github.com/zaidanm16/kang-backend).

PostgreSQL is the default database for every deployment method. Kong Gateway itself is managed separately.

## Getting started

Choose the deployment that fits your environment:

| Method | Included database | Instructions |
| --- | --- | --- |
| Helm | CloudNativePG operator and PostgreSQL cluster by default; external DB supported | [Helm README](helm/kang/README.md) |
| Docker Compose | PostgreSQL container with a named volume | [Compose README](compose/README.md) |
| Kubernetes manifest | Single PostgreSQL StatefulSet with persistent storage | [Kubernetes README](kubernetes/README.md) |

Clone this repository:

```sh
git clone https://github.com/zaidanm16/kang-deploy.git
cd kang-deploy
```

All commands in the method-specific guides assume this repository root unless they explicitly change directories. Create your own secrets before installation. Example files contain placeholders; actual `.env` and `backend.env` files are ignored by Git.

## Installation

For Docker Compose, copy the environment examples, set independent JWT and database secrets, and start the stack:

```sh
cd compose
cp .env.example .env
cp backend.env.example backend.env
# Set JWT_SECRET and POSTGRES_PASSWORD in .env using independent openssl rand -hex 32 values.
docker compose up -d
```

Open http://localhost:3000. See the Compose guide for public URLs, HTTPS and external services.

For Helm, follow the Helm guide to create the namespace and backend Secret, then install the chart:

```sh
helm upgrade --install kang ./helm/kang \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  -f your-values.yaml
```

The default chart installs CNPG and requires cluster-scoped permissions. Configure storage and networking for your cluster before installing.

For the standalone Kubernetes manifest, replace the JWT and matching database password placeholders in `kubernetes/kang.yaml`, then apply:

```sh
kubectl apply -f kubernetes/kang.yaml
```

Each deployment guide documents its configuration, storage, updates and operational limits.

## Releases

The [release workflow](.github/workflows/release.yaml) runs when a `v*` tag is pushed. The tag must match the chart version: chart `2.0.0` requires tag `v2.0.0`.

It validates and packages the chart, publishes it as an OCI artifact, and creates a GitHub Release containing:

- `kang-VERSION.tgz`: packaged Helm chart, including the pinned CNPG dependency.
- `kang-compose.tar.gz`: Compose configuration, examples and instructions.
- `kang.yaml` and `kubernetes-README.md`: standalone manifest and instructions.
- `SHA256SUMS`: checksums for the deployment artifacts.

The chart is published at `oci://ghcr.io/zaidanm16/kang-deploy/kang`. After a release has been published:

```sh
helm upgrade --install kang oci://ghcr.io/zaidanm16/kang-deploy/kang \
  --version 2.0.0 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  -f your-values.yaml
```

The workflow uses GitHub's built-in `GITHUB_TOKEN` with contents and packages write permissions. Repository Actions policy must allow those permissions. Set the GHCR package visibility to public if anonymous chart downloads are intended; private packages require registry login.

To publish, update `helm/kang/Chart.yaml`, review image pins and documentation, commit the changes, then push a matching tag:

```sh
git tag v2.0.0
git push origin v2.0.0
```

## Versioning

Deployment releases use semantic versions independently from the app repositories. The chart `version` is the deployment version and must match the release tag without its `v` prefix. `appVersion` records the frontend application version; backend and frontend image tags are pinned separately in each deployment configuration.

Use a major deployment version for incompatible configuration changes, a minor version for compatible deployment options, and a patch version for fixes. Chart OCI tags follow the chart's semantic version (`2.0.0`); GitHub release tags use `v2.0.0`. Application image tags retain their upstream `v` prefix.

## Contributing

Open an issue describing the deployment environment and the problem, or submit a focused pull request. Update the relevant guide and example values when changing configuration. Never include credentials, signed license keys, production endpoints or local agent configuration.

Before submitting changes:

```sh
helm dependency build ./helm/kang
helm lint ./helm/kang --set backend.secret.existingName=validation-secret
helm template kang ./helm/kang --set backend.secret.existingName=validation-secret
JWT_SECRET=validation-only POSTGRES_PASSWORD=validation-only \
  docker compose -f compose/compose.yaml --env-file compose/.env.example \
  config --no-env-resolution --quiet
```

Rendering validates configuration generation; a real deployment also depends on the cluster's controllers, storage and network setup. Report the environment used for runtime checks in your pull request.

## License

Copyright © 2026 Muhammad Zaidan. All rights reserved. This repository is proprietary; use and redistribution require written permission as described in [LICENSE](LICENSE). Bundled third-party components retain their own licenses.
