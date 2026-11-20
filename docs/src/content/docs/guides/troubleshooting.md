---
title: "Troubleshooting"
description: "Troubleshooting | Kang"
---

## Connection fails
Check the selected connection, Admin API address, authentication, and reachability from the Kang backend. For 401/403, check credentials and permissions. For timeouts, check DNS, firewall, and TLS.

## Resource or action missing
Check gateway compatibility, your role and team assignments, and the Kang plan. Clear list filters. Pro does not unlock Kong Enterprise features.

## Proxy request fails
Check route matching, service host/port, upstream health, and plugins. Test the proxy URL rather than the Admin API.

## Form values disappear
Sensitive fields are excluded from drafts. Drafts use the current tab session and depend on browser storage. Re-enter secrets and verify the selected connection.

## Charts are empty
Check Analytics preference, time range, real traffic, and the installation's metrics integration.

## License cannot be installed
Ask a global or organization administrator to check the complete key and expiry. Only a global administrator can remove a license. Environment-managed licenses require the installation operator. See [license renewal and backups](/kang/guides/plans/).

## Sign-in or session problems

| Symptom | First check |
| --- | --- |
| Login returns to the sign-in page | Check that `/auth` reaches the backend and the browser accepted the session and refresh cookies. Verify HTTPS, cookie scope, matching frontend/backend cookie names, and the configured frontend/API origins. |
| Reads work but changes return CSRF 403 | Check that the browser sends the CSRF cookie and corresponding header to the backend. Check CORS and proxy routing; do not disable CSRF as a workaround. |
| Session expired or revoked | Sign in again. If login is blocked, ask an administrator to check account status and lockout. |
| Requests return 429 | Stop retries, let the rate-limit window reset, and check for repeated login attempts or clients sharing an IP. Operators should check the configured limits and rate-limit store. |

When reporting a problem, include the action, selected gateway version, time, and redacted error. Keep passwords, tokens, private keys, and license keys out of the report.
