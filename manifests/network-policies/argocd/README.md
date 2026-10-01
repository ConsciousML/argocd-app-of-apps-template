<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/manifests/network-policies/argocd/. It is not meant to be read directly in this repository. -->

# `argocd-network-policies` Manifests Reference

The [`argocd-network-policies` manifests](./) define the `CiliumNetworkPolicy` rules for ArgoCD's own components. `argocd` is in [`default-deny.yaml`](../cluster-wide/default-deny.yaml)'s namespace list, so these rules are enforced.

For how `CiliumNetworkPolicy` enforcement works, read [`docs/network-policies.md`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/docs/network-policies.md) in the catalog.

## What's Inside

- **[network-policy-*.yaml](./)**: one `CiliumNetworkPolicy` per ArgoCD component (`application-controller`, `applicationset-controller`, `dex-server`, `notifications-controller`, `redis`, `repo-server`, and `server`)
- **[network-policy-shared-egress.yaml](network-policy-shared-egress.yaml)**: namespace-wide kube-apiserver and kube-dns egress for every pod in `argocd`

## Shared Egress

<!-- MIGRATE: explanation, move to the site's explanation docs -->
Shared egress is kept here instead of in [`../cluster-wide`](../cluster-wide) so this Application stays self-contained: it doesn't depend on `network-policies-cluster-wide` syncing for argocd's own pods to reach DNS or the API server.

## Why It's Defined Here

<!-- MIGRATE: explanation, move to the site's explanation docs -->
ArgoCD's own Deployments and StatefulSet are provisioned by the catalog's Terraform-managed Helm release (`units/eks/addons/argocd/helm`), not by an app-of-apps `Application`. There's no chart in this repo to add a `templates/network-policy.yaml` to. Same reasoning as [`argocd-server-grpc-service`](../../argocd-server-grpc-service): extra manifests targeting the Terraform-managed release live here as flat YAML.
