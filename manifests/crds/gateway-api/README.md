<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/manifests/crds/gateway-api/. It is not meant to be read directly in this repository. -->

# `crds-gateway-api` Manifests Reference

The [`crds-gateway-api` manifests](./) install the upstream [Gateway API](https://gateway-api.sigs.k8s.io/) CRDs (`GatewayClass`, `Gateway`, `HTTPRoute`, ...) from the [kubernetes-sigs/gateway-api](https://github.com/kubernetes-sigs/gateway-api) repository.

## What's Inside

- **[application.yaml](application.yaml)**: a nested ArgoCD `Application` sourcing manifests directly from the upstream repo instead of a local chart. `prune: false`, so a sync never deletes them and cascades into every `Gateway` and `HTTPRoute`
