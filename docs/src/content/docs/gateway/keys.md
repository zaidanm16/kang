---
title: "Keys and key sets"
description: "Keys and key sets | Kang"
---

Keys and key sets are Kong cryptographic resources used by compatible plugins. They are different from a consumer's Key Auth credential and from the Kang Pro license key.

## Create a key set

Open **Keys → Key Sets**, create a set, give it a meaningful name if applicable, and save. Use sets to group keys that a compatible plugin needs to discover together.

## Add a key

1. Open Keys or the key set's Keys section and choose the create action.
2. Enter the required **Key ID** (`kid`).
3. Provide the supported JWK or PEM representation required for your use case. Check the form/schema for required combinations; do not assume a label makes every key representation optional.
4. Select a key set when you want membership, add optional metadata/tags, and save.
5. Configure the consuming plugin to use the correct key or set and test its cryptographic operation.

Saving a key does not automatically enable JWT authentication on a route. For consumer JWT credentials, use the consumer's credential section instead.

## Rotation

Keep the identifier and material consistent. Introduce the new key, update the consuming application/plugin, verify behavior, then retire the old key. A private key or JWK may contain sensitive material and is excluded from draft recovery. Check references before deleting a key or set; do not treat deletion as a harmless UI cleanup.
