---
title: "Kang user guide"
description: "Kang user guide | Kang"
---

Kang is a self-hosted workspace for managing **Kong API Gateway**. Use it to configure your APIs, switch between gateways, inspect activity, and manage access for your team.

## Choose where to start

- **New installation:** [Install with Docker](/kang-deploy/installation/docker/) or [Helm](/kang-deploy/installation/kubernetes/), then [complete setup](/kang-deploy/getting-started/setup/).
- **Your team already runs Kang:** sign in with the account your administrator provides and read [Workspace basics](/kang-deploy/getting-started/workspace/).
- **Publish your first API:** follow [Create a service and route](/kang-deploy/getting-started/first-api/).
- **Manage your account:** see [Profile and security](/kang-deploy/account/profile/) and [Themes and language](/kang-deploy/account/preferences/).
- **Need collaboration:** compare [Free and Pro](/kang-deploy/guides/plans/).

## What belongs to Kang and what belongs to Kong?

Kong receives your API traffic and forwards it to upstream applications. Kang manages Kong through its Admin API; it is not the gateway proxy. Your Kong installation runs separately.

A **Kang user** signs into this dashboard. A **Kong consumer** represents an application or person using your APIs. A Kang connection points to a gateway; services, routes, and plugins belong to that gateway.

Kang stores users, connection definitions, audit records, and snapshots in its application database. A gateway configuration snapshot is not a backup of that whole database.

## Available features

Gateway Manager covers services, routes, consumers and consumer groups, plugins, Redis configurations, upstreams and targets, certificates, SNIs, vaults, keys, and key sets. The selected Kong version and edition determine which resources it supports.

Kang Free includes up to **2 connections**, **1 user**, Gateway Manager, and the audit activity list. Pro adds collaboration, unlimited connections and users, snapshots, and audit change details. Kang Pro does not grant a Kong Enterprise license.

These guides describe the current application. If a button is absent, first check your permissions, Kang plan, and gateway compatibility. Labels below use the English UI names so you can recognize them; the application also provides translated labels.
