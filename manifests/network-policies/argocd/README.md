# network-policies/argocd

Plain manifests (no Helm), one `CiliumNetworkPolicy` per ArgoCD component.

## Why It's Defined Here

ArgoCD's own Deployments and StatefulSet are provisioned by the catalog's Terraform-managed
Helm release (`units/eks/addons/argocd/helm`), not by an app-of-apps `Application`. There's no
chart in this repo to add a `templates/network-policy.yaml` to. Same reasoning as[`argocd-server-grpc-service`](../../argocd-server-grpc-service): extra manifests targeting
the Terraform-managed release live here as flat YAML.

See [`docs/network-policies.md`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/docs/network-policies.md) in the catalog repo for how `CiliumNetworkPolicy` enforcement works. `argocd` is not yet in [`default-deny.yaml`](../cluster-wide/default-deny.yaml)'s namespace list. These rules take effect once it's added there, after live verification with `hubble observe`.
