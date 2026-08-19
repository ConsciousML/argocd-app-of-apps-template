# network-policies/argocd

Plain manifests (no Helm), one `CiliumNetworkPolicy` per ArgoCD component, plus
`network-policy-shared-egress.yaml`: a `CiliumNetworkPolicy` for the kube-apiserver and
kube-dns egress every component needs. Kept here instead of in `../cluster-wide` so this
Application stays self-contained: it doesn't depend on `network-policies-cluster-wide` syncing
for argocd's own pods to reach DNS or the API server.

## Why It's Defined Here

ArgoCD's own Deployments and StatefulSet are provisioned by the catalog's Terraform-managed
Helm release (`units/eks/addons/argocd/helm`), not by an app-of-apps `Application`. There's no
chart in this repo to add a `templates/network-policy.yaml` to. Same reasoning as
[`argocd-server-grpc-service`](../../argocd-server-grpc-service): extra manifests targeting
the Terraform-managed release live here as flat YAML.

See [`docs/network-policies.md`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/docs/network-policies.md) in the catalog repo for how `CiliumNetworkPolicy` enforcement works. `argocd` is in [`default-deny.yaml`](../cluster-wide/default-deny.yaml)'s namespace list, so these rules are load-bearing, not just prepared for later.
