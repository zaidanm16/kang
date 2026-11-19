---
title: "Free, Pro, and license renewal"
description: "Free, Pro, and license renewal | Kang"
---

A Kang license applies to the **whole Kang installation**, not to a browser tab or a Kong gateway. Manage it under **System → Kang License** (`/license`). It does not manage Kong Enterprise licenses.

## Compare plans

| Capability | Free | Pro |
| --- | --- | --- |
| Gateway Manager | Full access, subject to Kong support and user permissions | Same gateway compatibility requirements |
| Connections | Up to **2** | Unlimited by the plan |
| Users | **1** | Unlimited by the plan |
| Organizations and teams | Not included | Included |
| Snapshots | Not included | Included |
| Audit logs | Activity list | Activity and change details |
| Expiry | None | Signed license expiry date |

Without a license, a new installation uses Free. Connection and user limits count records across the installation. Pro removes those limits, not the infrastructure's capacity limits or account permission checks.

## Upgrade to Pro

1. Obtain a signed Pro license from your Kang provider. The application installs license keys; it does not provide an in-app checkout or issue keys for you.
2. Sign in as a **global administrator**: an admin account without an organization assignment.
3. Open Kang License and choose **Install Pro license**.
4. Paste the complete key into the dialog and install it.
5. Confirm the current plan, licensee, and expiry. Return to the intended feature and verify access with the appropriate permissions.

Do not edit the key contents. If installation fails, check that the complete key was pasted, that it is valid for the current time, and ask your operator to verify the installation's license configuration. A non-global administrator cannot install a license just because their role is named admin within an organization.

## Configure UI-managed licenses

The backend needs `KANG_LICENSE_PUBLIC_KEYS`, a JSON object mapping a key ID to its base64 Ed25519 public key. Obtain this object from the license issuer. A public key verifies signatures; it cannot issue licenses. Never put the signing private key in a container, Helm values, a Kubernetes Secret used by the application, or Git.

Leave `KANG_LICENSE` unset or empty. The application then reads the installed token from its database, and a global administrator can install, replace, or remove it through `/license`. Restarting the backend does not remove a database-installed license.

For Compose, put the public-key object in `backend.env`. For Helm, store it under `KANG_LICENSE_PUBLIC_KEYS` in the Secret named by `backend.secret.existingName`; the chart exposes that Secret through `envFrom`. Use `backend.extraEnv` with `valueFrom.secretKeyRef` if you need an explicit reference. Keep actual tokens and private values out of committed values files.

### Switch from environment-managed to UI-managed

1. Save the current Helm values and back up the database/Secret. Follow the [Helm update procedure](/kang/guides/operations/#update-an-existing-helm-release).
2. While the current environment-managed license is valid, check the license page. The backend persists that valid token in `license_states`; preserve this row so the installation stays licensed during the change.
3. Remove `KANG_LICENSE` from `backend.env`, `backend.extraEnv`, and any Secret or ConfigMap exposed through `envFrom`. Removing only an explicit deployment entry is not enough if an `envFrom` Secret still contains the token. Preserve `JWT_SECRET`, `KONG_CREDENTIAL_ENCRYPTION_KEY`, and `KANG_LICENSE_PUBLIC_KEYS`.
4. Apply the edited values with Helm, keeping the current chart version, and ensure backend pods restart with the new environment. External Secret changes alone do not restart pods.
5. Verify the existing Pro license remains valid and the environment-managed notice disappears. On an already licensed installation, choose **Actions → Replace** and paste the new token. On Free, choose **Install Pro license**.

Do not remove the license row or choose **Remove** merely to enable UI replacement: that would switch the installation to Free.

## Issue a license as the installation operator

The signing CLI lives in the separate [kang-backend repository](https://github.com/zaidanm16/kang-backend/tree/main/cmd/kang-license). Run it from a backend checkout using that repository's required Go version; it is not a command shipped in this deployment repository or the API container. Use the existing signing key for renewals. Generate a new pair only when provisioning a new issuer:

```sh
umask 077
mkdir -p "$HOME/.config/kang-issuer"
go run ./cmd/kang-license keygen \
  --key-id primary \
  --private-key "$HOME/.config/kang-issuer/primary.b64" \
  > "$HOME/.config/kang-issuer/public-keys.json"
```

Keep `primary.b64` in the issuer's secret store with a recoverable backup. Configure only the contents of `public-keys.json` as `KANG_LICENSE_PUBLIC_KEYS`. For an existing issuer, use its matching private key instead of regenerating it.

```sh
umask 077
go run ./cmd/kang-license issue \
  --key-id primary \
  --private-key "$HOME/.config/kang-issuer/primary.b64" \
  --licensee "Your organization" \
  --expires "2027-01-31T23:59:59+07:00" \
  > "$HOME/.config/kang-issuer/pro.license"
```

Replace the example licensee and expiry. `--expires` must be a future RFC3339 timestamp with an explicit offset; the example is the end of 31 January in WIB (UTC+7), not midnight at its start. The CLI emits the signed Pro token. Deliver the complete file privately to the global administrator to paste into the UI. Generating the file does not install it or change the encryption key used for Kong credentials.

## Renew or replace

On an installation with a license, use **Actions → Replace** and install the replacement key. Confirm the new expiry afterward. Renewal changes the license; it does not replace your application database or gateway configuration.

If the page says the license is managed by `KANG_LICENSE`, UI replacement/removal is unavailable. Ask the operator to update the deployment token or follow the switch-to-UI procedure above.

## Expiry

Pro has a **7-day grace period** after its expiry. During grace, Pro features remain available and the UI warns about the lock date. After grace, Kang application access locks; login and license management remain available. Your data is retained, and Kong gateway traffic continues separately.

A validation failure can also restrict access; it is not necessarily an expired license. Ask the operator to inspect verification configuration. Free itself has no expiry.

## Return to Free

A global administrator can use **Actions → Remove** and confirm, unless the license is environment-managed. This activates Free; it is an explicit action, not an automatic downgrade at expiry. Existing connections, users, and other data are retained. New connection/user creation is blocked while usage meets or exceeds the Free limits, and Pro-only features become unavailable. Do not assume existing records are automatically deleted or disabled to reduce usage.
