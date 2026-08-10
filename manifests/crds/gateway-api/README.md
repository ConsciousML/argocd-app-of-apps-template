# crds-gateway-api

Installs the upstream [Gateway API](https://gateway-api.sigs.k8s.io/) CRDs (`GatewayClass`, `Gateway`, `HTTPRoute`, ...) from the [kubernetes-sigs/gateway-api](https://github.com/kubernetes-sigs/gateway-api) repository.

## What's Inside

- **[application.yaml](application.yaml)**: sources manifests directly from the upstream repo instead of a local chart. `prune: false` so a sync never deletes them and cascades into every `Gateway` and `HTTPRoute`
