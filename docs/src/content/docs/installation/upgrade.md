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
  --namespace kang \
  -f values.updated.yaml
```

Start `values.updated.yaml` from an export of the installed release, not from chart defaults. Follow the [Helm update procedure](/kang/guides/operations/#update-an-existing-helm-release) to preserve existing Secrets, storage and gateway settings.

## If the rollout fails

Check backend startup logs for migration errors and confirm whether migrations ran before rolling back. A Helm rollback or previous Compose image restores application configuration or binaries, **not the database schema, externally managed Secrets, or data**. Use the old image against the current database only if the previous version supports its schema and migration history.

If it does not, stop writers and restore the matching pre-upgrade database and Secrets to a separate target. Check how much post-upgrade data would be lost before switching. After recovery, verify login, license, and at least one saved authenticated gateway connection, not just readiness probes.

## Release notes

Read the release notes of every version between your current and target version for breaking changes before upgrading.
