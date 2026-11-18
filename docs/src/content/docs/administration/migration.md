---
title: "Optional full migration"
description: "Optional full migration | Kang"
---

**Full Migration** is an advanced maintenance feature, not the normal way to copy a few services. It is hidden by default and requires operator-enabled frontend support, a configured migration worker, and a global administrator with migration permissions. The standard deployment does not include a migration-worker image.

If you do not see this action, use [snapshot clone and restore]((/kang//administration/snapshots/) for logical configuration transfer, or ask your installation operator whether full migration is supported.

## If your installation enables it

1. Arrange a maintenance window and verified backups with the gateway/database operators.
2. Open Full Migration and provide the source and target PostgreSQL connection information privately.
3. Run **preflight** and inspect source/target database details and compatibility. Resolve failures before continuing.
4. If the target contains data, review **Backup & replace** versus **Logical merge**. Replace clears the target after backup and copies database data; the target is unavailable during the operation. Logical merge opens the Clone Snapshot workflow instead of starting a database migration job.
5. For replacement, confirm that source and target Kong traffic and database writes are stopped, then complete the explicit confirmation.
6. Monitor the job and inspect results/backups before restoring traffic.

Do not equate this with a Kang application upgrade or assume every pair of Kong/PostgreSQL versions is compatible. Do not paste database credentials into audit comments, tickets, or shared screenshots.
