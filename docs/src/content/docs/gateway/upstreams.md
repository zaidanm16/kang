---
title: "Upstreams and targets"
description: "Upstreams and targets | Kang"
---

An upstream is a named pool of backend targets. A service can use that name as its host so Kong balances traffic across the pool.

## Build a pool

1. Open **Upstreams** and create an upstream with a distinct name.
2. Choose a supported balancing algorithm and review optional settings such as slots and host-header behavior.
3. Save, then open its **Targets** section.
4. Add a reachable target address and port with the intended weight. Repeat for other application instances.
5. Point the gateway service's host at the upstream name, then test requests through its route.

An upstream with no usable targets cannot serve traffic. Target addresses must be reachable from Kong. Adding targets to Kang's gateway configuration does not deploy the target applications.

## Health checks

Active health checks probe targets; passive checks react to observed request results. Configure the check protocol, timing, timeout, concurrency, healthy/unhealthy status codes, and thresholds that the form exposes. For HTTP checks, use an endpoint that reflects readiness rather than an arbitrary route that always fails.

Check both settings and target status before forcing health-state actions. A successful readiness endpoint does not guarantee every application operation succeeds.

## Change capacity safely

Add and verify a new target before removing an old one. Inspect weights and health to understand traffic distribution. If requests fail after a pool change, confirm service host, upstream name, target port, DNS, and health-check configuration. Deleting an upstream used by a service can interrupt routing; update references first.
