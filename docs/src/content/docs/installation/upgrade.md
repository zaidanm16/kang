---
title: Upgrade
description: Back up the application database and upgrade Kang to a new version.
---

Back up the application database before every upgrade. For PostgreSQL, use a consistent backup such as `pg_dump`. Gateway configuration snapshots are not a substitute for backing up Kang's application database.

## Docker Compose

Change the application image tags in `.env` (for example `BACKEND_IMAGE`), then run:

```sh
docker compose pull
docker compose up -d
```

`docker compose down` retains the database volume. Adding `-v` deletes that volume and its data.

## Kubernetes

Point `--version` at the new chart version and set the new application image tags in your values, then run:

```sh
helm upgrade kang oci://ghcr.io/zaidanm16/kang \
  --version <new-chart-version> \
  --namespace kang
```

## Release notes

Read the release notes of every version between your current and target version for breaking changes before upgrading.
