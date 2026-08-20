# network-policies/kube-system

Plain manifests (no Helm), one `CiliumNetworkPolicy` per component. `coredns`, `metrics-server`, `karpenter`, `ebs-csi-controller`, and `ebs-csi-node` are all Terraform or EKS-addon managed, with no ArgoCD-owned chart to colocate a `templates/network-policy.yaml` in, so they land here as flat YAML.

`hubble-relay` and `hubble-ui` do have an ArgoCD-owned chart (`charts/cilium`), but their policies still live here instead of there: that chart's release also creates the `CiliumNetworkPolicy` CRD, and a `CiliumNetworkPolicy` resource in the same release fails ArgoCD's pre-sync validation on a fresh cluster (the CRD isn't registered yet when the CR is checked). This app syncs at a later wave than `cilium`, so the CRD is already established by the time these apply. See [`charts/cilium`](../../../charts/cilium)'s README.

`network-policy-shared-egress.yaml` is namespace-wide: kube-apiserver and coredns egress for every component in this namespace, including `aws-load-balancer-controller`, `hubble-relay`, and `hubble-ui`, which are deployed by other charts (`charts/aws-lbc`, `charts/cilium`). Cilium enforces by pod labels and namespace, not by which Application created the resource, so one file covers all of them.

This Application syncs at an earlier wave than `network-policies-cluster-wide`, so these allow rules exist before `kube-system` (already in [`default-deny.yaml`](../cluster-wide/default-deny.yaml)'s namespace list) gets denied, the same reasoning as [`../argocd`](../argocd/README.md)'s own copy.

`aws-node`, `kube-proxy`, `cilium`, `cilium-operator`, and `eks-pod-identity-agent` have no policy here. They're all `hostNetwork: true`, which Cilium collapses into the single per-node `reserved:host` identity when host firewall isn't enabled. There's no distinct endpoint to attach a `CiliumNetworkPolicy` to, and `default-deny.yaml`'s namespace-scoped selector can't reach `reserved:host` either. Confirmed empirically: restarting each of them produced zero Hubble-visible flows.

See [`docs/network-policies.md`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/docs/network-policies.md) in the catalog repo for how `CiliumNetworkPolicy` enforcement works.
