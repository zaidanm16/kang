---
title: "Gateway configuration and compatibility"
description: "Gateway configuration and compatibility | Kang"
---

**Configuration** displays the selected Kong node's runtime configuration. It helps inspect listeners, datastore settings, Nginx directives, and plugin settings exposed by the Admin API. It is a read-only view, not an editor for `kong.conf`.

## Use the page

1. Confirm the selected connection.
2. Open Configuration and inspect the relevant values.
3. Compare them with the intended gateway setup or a second environment in another tab.
4. To change startup settings, ask the Kong operator to update the gateway's configuration/environment and apply the appropriate restart or reload procedure.

Do not confuse these values with Kang's own application configuration. A change to a gateway's database or listener cannot be made simply by changing its display name in Connections.

## Three independent requirements

| Requirement | Example |
| --- | --- |
| Kang plan | Snapshots, teams, and audit change details need Pro |
| Kang account permission and scope | A user must have permission to edit a service and access its connection |
| Kong gateway support | A particular plugin, vault provider, or enterprise resource must be supported by that Kong version/edition |

All applicable requirements must be satisfied. A disabled resource is not always a subscription problem. Check connection test/compatibility results and the gateway version shown in Overview. Upgrading Kang does not upgrade Kong automatically, and installing a Kang Pro license does not install a Kong Enterprise license.

If the gateway schema rejects a field, inspect the field-specific error and your Kong version's documentation rather than repeatedly submitting the same payload. Read-only or restricted Admin API credentials may permit inventory access but reject writes.
