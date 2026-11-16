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

## Renew or replace

On an installation with a license, use **Actions → Replace** and install the replacement key. Confirm the new expiry afterward. Renewal changes the license; it does not replace your application database or gateway configuration.

If the page says the license is managed by `KANG_LICENSE`, contact your installation operator to update that deployment value and restart the backend. UI replacement/removal is not available for an environment-managed license.

## Expiry

Pro has a **7-day grace period** after its expiry. During grace, Pro features remain available and the UI warns about the lock date. After grace, Kang application access locks; login and license management remain available. Your data is retained, and Kong gateway traffic continues separately.

A validation failure can also restrict access; it is not necessarily an expired license. Ask the operator to inspect verification configuration. Free itself has no expiry.

## Return to Free

A global administrator can use **Actions → Remove** and confirm, unless the license is environment-managed. This activates Free; it is an explicit action, not an automatic downgrade at expiry. Existing connections, users, and other data are retained. New connection/user creation is blocked while usage meets or exceeds the Free limits, and Pro-only features become unavailable. Do not assume existing records are automatically deleted or disabled to reduce usage.
