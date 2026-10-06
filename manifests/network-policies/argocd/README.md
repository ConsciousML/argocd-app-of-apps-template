<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/manifests/network-policies/argocd/. It is not meant to be read directly in this repository. -->

# `argocd-network-policies` Manifests Reference

The [`argocd-network-policies` manifests](./) define the `CiliumNetworkPolicy` rules for ArgoCD's own components. `argocd` is in [`default-deny.yaml`](../cluster-wide/default-deny.yaml)'s namespace list, so these rules are enforced.

For how `CiliumNetworkPolicy` enforcement works, and why these policies live here, see [How Network Policies Work](/docs/security/how-network-policies-work/#avoiding-a-lockout).

## What's Inside

- **[network-policy-*.yaml](./)**: one `CiliumNetworkPolicy` per ArgoCD component (`application-controller`, `applicationset-controller`, `dex-server`, `notifications-controller`, `redis`, `repo-server`, and `server`)
- **[network-policy-shared-egress.yaml](network-policy-shared-egress.yaml)**: namespace-wide kube-apiserver and kube-dns egress for every pod in `argocd`
