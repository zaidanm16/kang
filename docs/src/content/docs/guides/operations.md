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

`KONG_CREDENTIAL_ENCRYPTION_KEY` protects saved Kong Admin API credentials, not database login passwords or license signatures. Set a separate stable random value before saving the first authenticated connection. If it is unset, the backend uses `JWT_SECRET` as key material, so changing that JWT secret also affects credential decryption. License verification uses the separate `KANG_LICENSE_PUBLIC_KEYS` setting; see [UI license management](/kang/guides/plans/).

## Enable photo uploads with Cloudinary

Profile photos and organization logos are uploaded by the backend to **Cloudinary**. To use these features, create a Cloudinary product environment and obtain all three settings from its API Keys page:

```dotenv
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
```

For Docker Compose, add these settings to the private `backend.env` file and recreate the backend container. For Helm, use an existing Kubernetes Secret rather than `backend.env` values (those values render into a ConfigMap). For example, save the three lines with real values in `/secure/cloudinary.env`, restrict the file to its owner, then create a dedicated Secret:

```sh
kubectl -n kang create secret generic kang-cloudinary \
  --from-env-file=/secure/cloudinary.env
```

Append this reference to the exported Helm values, preserving any existing `extraEnvFrom` entries:

```yaml
backend:
  extraEnvFrom:
    - secretRef:
        name: kang-cloudinary
```

Follow the Helm update procedure below. If only the Secret contents change, restart the backend pods to load them. Never expose the API secret through `NEXT_PUBLIC_*`, commit it, or put real credentials in documentation.

The backend needs outbound HTTPS access to Cloudinary; browsers need access to the returned `res.cloudinary.com` image URLs. PNG, JPEG, and WebP uploads are limited to **5 MB**. Without all three settings, uploads are unavailable. To verify, upload a test profile photo or organization logo using an authorized account and confirm it displays after refresh. If upload fails, check credentials, outbound connectivity, and Cloudinary account limits without logging secrets.

Image files live in Cloudinary; the Kang database stores their URLs. Back up/manage media assets separately from the application database. These are delivered as image URLs, so do not upload confidential documents as photos.

## Update an existing Helm release

Export the installed release's values before editing them. Keep the cluster context and namespace explicit so you do not change the wrong installation. The example uses `kang` in namespace `kang`; replace `destination-context` and the chart version with the installed release's values.

```sh
umask 077
CTX=destination-context
NS=kang
RELEASE=kang
helm list --kube-context "$CTX" -n "$NS"
helm get values "$RELEASE" --kube-context "$CTX" -n "$NS" -o yaml > values.current.yaml
helm get manifest "$RELEASE" --kube-context "$CTX" -n "$NS" > manifest.current.yaml
cp values.current.yaml values.updated.yaml
```

Edit `values.updated.yaml`, retaining unrelated database, storage, gateway, image, and resource settings. Reference the existing backend Secret rather than putting secret contents in the file:

```yaml
backend:
  secret:
    existingName: kang-backend-secrets
  extraEnv:
    - name: KONG_CREDENTIAL_ENCRYPTION_KEY
      valueFrom:
        secretKeyRef:
          name: kang-backend-secrets
          key: KONG_CREDENTIAL_ENCRYPTION_KEY
    - name: KANG_LICENSE_PUBLIC_KEYS
      valueFrom:
        secretKeyRef:
          name: kang-backend-secrets
          key: KANG_LICENSE_PUBLIC_KEYS
```

This is a fragment, not a replacement for your exported values. The referenced Secret must already contain these keys. Preserve its `JWT_SECRET` and any other existing entries; update it through your secret manager or a targeted Secret patch. The chart also exposes `backend.secret.existingName` through `envFrom`, so explicit references are optional unless you need to override another environment source. Omit `KANG_LICENSE` from all sources for UI-managed licenses.

```sh
helm upgrade "$RELEASE" oci://ghcr.io/zaidanm16/kang \
  --version 3.1.3 \
  --kube-context "$CTX" -n "$NS" \
  -f values.updated.yaml --wait --timeout 5m
```

Keep the currently installed chart version for a configuration-only change; do not use the example version to downgrade a newer installation. Review a dry-run before applying, and protect its output because Helm manifests can include Secrets. Restart backend pods if only an external Secret changed: its existing process environment will not refresh automatically.

Avoid `kubectl set env` for lasting Helm configuration. Previous manual edits can cause Helm 4 server-side ownership conflicts. Inspect the reported fields first; `--force-conflicts` is appropriate only after confirming that Helm should take over those specific changes. It is not the same as `--force-replace`. Preserve the previous values and Secret for rollback, then verify authenticated API requests after the rollout, not just pod readiness.

## Move the Kang application database

The Kang database contains accounts, password hashes, organizations, teams, permissions, connection records, session preferences, audit logs, snapshots, and migration history. Newer versions also contain setup and license state. It does **not** contain the live services/routes/plugins/consumers stored by Kong Gateway. If the gateways stay the same, leave their databases alone. The UI's **Full Migration** feature concerns Kong database transfer, not this application move.

1. Record source and destination backend/PostgreSQL versions. Use a dump client compatible with the source server and a destination supported by the target backend. Do not migrate to an older Kang schema by discarding migration history.
2. Back up both databases and their relevant secrets. Preserve the source's effective `KONG_CREDENTIAL_ENCRYPTION_KEY`; if it used the JWT fallback, preserve that key material explicitly. Include any filesystem uploads or external object storage separately. Database passwords/roles are managed separately from the dump.
3. Stop source application writers for the final cutover and stop destination backend replicas, including background jobs. Record replica counts and restore them afterward. Keep Kong gateway traffic running only if Kong itself is outside the migration.
4. Take a final custom-format source dump. Prefer restoring into a new empty destination database owned by the application role. Do not merge it into the target's pre-created newer schema or assume `--clean --if-exists` removes every target-only dependency. Replacing an existing target database requires a verified backup and explicit approval.

The example assumes PostgreSQL service definitions `kang-source` and `kang-restore` have been configured privately, with passwords in a protected passfile (mode `0600`). `kang-restore` must point to the new empty destination database, and its connecting role must be allowed to `SET ROLE kang`:

```sh
umask 077
pg_dump --dbname="service=kang-source" --format=custom --file=kang-source.dump
pg_restore --list kang-source.dump > kang-source.contents
pg_restore --dbname="service=kang-restore" \
  --role=kang --no-owner --no-acl \
  --single-transaction --exit-on-error kang-source.dump
```

`--no-owner` skips source ownership commands; the restoring role still owns the new objects. Restoring as `postgres` without `--role=kang` can leave the application unable to alter its tables during upgrades. Grants alone do not grant ownership. Inspect owners with `SELECT schemaname, tablename, tableowner FROM pg_tables WHERE schemaname = 'public';`. Correct only the application's objects; do not run a blanket `REASSIGN OWNED BY postgres` against system-owned objects.

5. Point the target deployment's DSN Secret to the restored database. Keep the old database and backup available for rollback. Start one backend replica with `MIGRATE_ON_START=true`; it uses the restored `schema_migrations` history to apply pending migrations. Review logs before restoring normal replicas.
6. On versions with initial setup, initialization recognizes existing users when creating setup state. An upgraded old database with users should not require a new administrator. If a leftover destination `setup_states` row survives a partial restore, investigate rather than creating a duplicate administrator.
7. Compare source and restored table counts, including soft-deleted rows. Login, list connections with the authenticated API, inspect teams/permissions, audit logs, and snapshots, and test a saved authenticated Kong connection from the backend network. Healthy pods and matching counts alone do not prove credential decryption works.

A PostgreSQL port-forward targets a particular pod even when you specify a Service; it does not reconnect transparently after that pod is lost. Keep its process/logs visible. A reset does not by itself prove OOM or database corruption. For an unreliable tunnel, stream the archive through `kubectl exec -i` to `pg_restore` in the destination pod. CNPG container filesystems may be read-only, so do not assume `/tmp` is writable. Stop on the first restore error; do not hide its exit status behind `head` or `grep`.

## Rotate Kong credential encryption key

Changing the environment value alone makes existing encrypted credentials unreadable. There is no built-in key-rotation CLI or multi-key transition. Keep the existing key until you have a tested rotation procedure and a maintenance window.

The backend implementation is [secrets/cipher.go](https://github.com/zaidanm16/kang-backend/blob/main/internal/secrets/cipher.go): the AES-256-GCM key is **SHA-256 of the exact UTF-8 environment text** after configuration trims surrounding whitespace. A value generated by `openssl rand -hex 32` is still text: do **not** hex-decode it into raw AES key bytes. Stored values use `enc:v1:` followed by unpadded base64url of a 12-byte nonce and the GCM ciphertext/authentication tag.

1. Back up the database, old key, deployment values, and current Secret. Verify every nonempty saved credential decrypts with the source key. Keep plaintext out of logs and temporary files.
2. Stop every backend writer/replica so old and new processes cannot mix ciphertext under different keys. Generate the replacement secret and derive it exactly as the backend does.
3. Decrypt using the old derived key and re-encrypt using the new derived key with a fresh random nonce for each credential. Preserve empty values and all non-credential fields. Apply updates in one transaction, with guards against concurrent changes; roll back the entire batch on any failure.
4. Update the Secret and exported Helm values/references together, then restart the backend with the new environment. Do not leave old-key pods serving the newly encrypted database.
5. Verify **all** affected ciphertext decrypts with the backend derivation and matches the original plaintext in memory. Then check authenticated `/api/v1/user/kong-instances`, the license page, and a real Kong connection. The crypto check must use the application's derivation, not merely the same potentially incorrect helper used to write the data.

Keep the old key with old backups until their retention period ends. Rollback must restore matching ciphertext **and** key material; reverting only the env value or only the database recreates the mismatch. Rotating this key does not require issuing another license or changing its signing keys.
