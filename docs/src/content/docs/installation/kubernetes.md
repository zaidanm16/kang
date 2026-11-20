---
title: Kubernetes with Helm
description: Install the published Kang OCI chart.
---

The published chart and application images are public; registry login is not required.


Use the **published Helm chart** with an existing Kubernetes cluster and a default StorageClass. The default chart also installs the CloudNativePG operator, which requires cluster-scoped permissions.

```sh
# Create the namespace and a Secret holding the backend JWT signing key
kubectl create namespace kang
secret_file="$(mktemp)"
openssl rand -hex 32 > "$secret_file"
kubectl -n kang create secret generic kang-backend-secrets \
  --from-file=JWT_SECRET="$secret_file"
rm -f "$secret_file"

# Install the chart from the public OCI registry (version matches the release)
helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.1.4 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  --set backend.env.AUTH_COOKIE_SECURE=false
```

- The Secret provides the signing key the backend needs; keeping it out of the chart values keeps it out of your shell history and Helm release record.
- `helm upgrade --install` deploys the CloudNativePG operator and a PostgreSQL cluster by default, which requires cluster-scoped permissions.
- `AUTH_COOKIE_SECURE=false` is for local HTTP testing only — keep it `true` (the default) behind HTTPS.

## Use an existing CloudNativePG operator

If the cluster already has a CNPG operator, **set `cnpg.operator.enabled: false`**. Keep `cnpg.cluster.enabled: true` so the chart creates only Kang's PostgreSQL `Cluster`, not another operator:

```yaml
cnpg:
  operator:
    enabled: false
  cluster:
    enabled: true
```

Save this in your values file and pass it with `-f kang-values.yaml` in the install command above. Confirm the existing operator is healthy, the `clusters.postgresql.cnpg.io` CRD exists, and the operator watches the Kang namespace. The operator may run in a different namespace; do not install a second one just for Kang.

This creates a **new database cluster** managed by the existing operator; it does not reuse an existing PostgreSQL database. To connect to an existing database, disable `cnpg.cluster.enabled` too and configure the external DSN Secret in the chart guide. Do not disable/remove a Helm-managed operator on a running release without checking its ownership and the other databases it manages.

## Photo uploads

Profile photos and organization logos require backend Cloudinary credentials. Follow [Cloudinary setup](/kang/guides/operations/#enable-photo-uploads-with-cloudinary) using Kubernetes Secrets; credentials are optional only when you do not need uploads.

## Local access

For local access, run these in separate terminals (`kubectl port-forward` tunnels the in-cluster Services to your local machine), then open http://localhost:3000:

```sh
kubectl -n kang port-forward svc/kang-backend 8080:8080
kubectl -n kang port-forward svc/kang-frontend 3000:3000
```

See the [chart guide](https://github.com/zaidanm16/kang/blob/main/charts/kang/README.md) for external databases, storage, HTTPS, Ingress, Gateway API, and custom values. A [standalone Kubernetes manifest](https://github.com/zaidanm16/kang/blob/main/kubernetes/README.md) is also available.
