---
title: "Plugins and scopes"
description: "Plugins and scopes | Kang"
---

Plugins add authentication, traffic control, transformations, logging, and other behavior. Availability and configuration are determined by the connected Kong gateway, not just by the Kang catalog.

## Add a plugin

1. Select the intended connection.
2. Open **Plugins** or the Plugins tab on a service, route, consumer, or supported consumer group.
3. Choose a plugin available on that gateway.
4. Check the scope before filling configuration. For example, a service-scoped `http-log` plugin should refer to the intended service.
5. Fill required schema fields, review protocols/enabled status and optional tags, and save.
6. Send a representative request through the proxy and verify the plugin's effect.

## Understand Applied To

The **Applied To** column distinguishes global plugins from scoped instances. A global plugin can affect traffic across the gateway. A scoped plugin is associated with the resources shown; supported scope combinations depend on the plugin schema.

Several instances can share a plugin name while targeting different resources. Before editing or deleting `http-log`, for example, inspect **Applied To** rather than relying on the name alone. Audit records for scoped plugin changes also show entity context when available.

## Edit configuration

Use the form generated for the selected plugin. Required fields and accepted types vary: a number, boolean, array, and object are not interchangeable. Follow inline validation and gateway errors. Secrets and plugin configuration may be excluded from saved browser drafts, so check sensitive fields after refresh.

Disabling a plugin changes enforcement without necessarily deleting its stored configuration. Removing it removes that configured instance; neither action uninstalls plugin code from Kong.

## If a plugin is unavailable

Confirm gateway version, edition, installed plugin support, and your permission to manage plugins. Upgrading to Kang Pro does not install a Kong plugin or unlock Kong Enterprise licensing. Use the plugin's documentation link for the exact settings accepted by your gateway version.
