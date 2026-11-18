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
Ask a global administrator to check the complete key and expiry. Environment-managed licenses require the installation operator. See [license renewal]((/kang//guides/plans/).

When reporting a problem, include the action, selected gateway version, time, and redacted error. Keep passwords, tokens, private keys, and license keys out of the report.
