---
title: "Routes"
description: "Routes | Kang"
---

Routes match incoming requests and associate them with services or supported gateway behavior. Open **Routes**, select the correct connection, and choose the create action.

## Configure matching

Give the route a recognizable name, select a service when forwarding to an upstream, and choose protocols. For a simple HTTP route, start with a path and your service, then add restrictions deliberately.

| Field | Purpose |
| --- | --- |
| Protocols | Protocol families accepted by the route; incompatible families cannot always be combined |
| Methods | Restrict HTTP methods such as GET or POST |
| Paths | Match request paths, such as `/catalog` |
| Hosts | Match the hostname requested by the client |
| Headers | Add header match conditions |
| Sources / Destinations | IP/CIDR and/or port conditions for supported protocols; each entry needs an IP or port |
| SNIs | Match TLS server names for supported protocols |

Not every matcher is meaningful for every protocol. Validation follows the selected Kong schema. Route names and service selection are not a universal substitute for valid match conditions.

## Forwarding behavior

**Strip Path** removes the matching path prefix before forwarding. **Preserve Host** controls whether the original host header is kept. Review request/response buffering, regex priority, and HTTPS redirect status only when your route needs them.

Save and inspect the configuration. Test through the proxy using the same method, path, hostname, and headers that real clients send. Testing the Admin API does not test route matching.

## Edit or delete

Changing a route can redirect existing client traffic immediately. Check its associated service and plugins before saving. Delete only the intended route and review confirmation; removing a route does not necessarily remove its service. If a request no longer matches, look for an overly restrictive host/method/header condition or a different selected connection.
