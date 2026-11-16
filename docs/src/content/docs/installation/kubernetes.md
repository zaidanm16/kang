---
title: Kubernetes with Helm
description: Install the published Kang OCI chart.
---

The published chart and application images are public; registry login is not required.


Use the **published Helm chart** with an existing Kubernetes cluster and a default StorageClass. The default chart also installs the CloudNativePG operator, which requires cluster-scoped permissions.

```sh
kubectl create namespace kang
secret_file="$(mktemp)"
openssl rand -hex 32 > "$secret_file"
kubectl -n kang create secret generic kang-backend-secrets \
  --from-file=JWT_SECRET="$secret_file"
rm -f "$secret_file"

helm upgrade --install kang oci://ghcr.io/zaidanm16/kang \
  --version 3.0.0 \
  --namespace kang \
  --set backend.secret.existingName=kang-backend-secrets \
  --set backend.env.AUTH_COOKIE_SECURE=false
```

For local access, run these in separate terminals, then open http://localhost:3000:

```sh
kubectl -n kang port-forward svc/kang-backend 8080:8080
kubectl -n kang port-forward svc/kang-frontend 3000:3000
```

See the [chart guide](https://github.com/zaidanm16/kang-deploy/blob/main/charts/kang/README.md) for external databases, storage, HTTPS, Ingress, Gateway API, and custom values. A [standalone Kubernetes manifest](https://github.com/zaidanm16/kang-deploy/blob/main/kubernetes/README.md) is also available.

