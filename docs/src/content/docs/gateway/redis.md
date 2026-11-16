---
title: "Redis configurations"
description: "Redis configurations | Kang"
---

**Redis Configurations** defines reusable Redis connection settings for compatible Kong plugins. It does not deploy a Redis server or configure the database that stores Kang users.

## Create a configuration

1. Select the gateway and open Redis Configurations.
2. Choose the type supported by your gateway/plugin: the form offers simplified Open Source Host/Port, Enterprise Host/Port, Cluster, and Sentinel variants.
3. Fill the required host/port or node addresses. For Sentinel, review the master and role-related settings exposed by the form.
4. Configure authentication, database, TLS, timeouts, and other applicable fields.
5. Save, reference the configuration from a plugin that supports it, and test that plugin with real traffic.

Kong, not the browser, connects to Redis. Ensure DNS, firewall, credentials, and TLS requirements match the Redis service. Some hosted Redis offerings provide both HTTP and Redis protocol endpoints; use the protocol supported by the Kong plugin.

## Scope of support

Enterprise variants require the corresponding Kong support. Kang Pro does not supply that entitlement. A reusable configuration is not automatically attached to every plugin: check the plugin's configuration and supported reference mechanism.

## Change or delete

Inspect all plugins sharing the configuration before editing credentials, nodes, or TLS. A single shared change can affect rate limiting, caching, or other policies on multiple resources. Re-enter secrets after refresh when required; browser draft recovery deliberately excludes sensitive fields.
