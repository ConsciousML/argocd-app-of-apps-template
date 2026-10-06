<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/helm_charts/network-policies/kube-system/. It is not meant to be read directly in this repository. -->

# `network-policies-kube-system` Helm Chart Reference

The [`network-policies-kube-system` chart](./) renders the `CiliumNetworkPolicy` rules for `kube-system` addons managed by Terraform or EKS: `coredns`, `metrics-server`, `karpenter`, `ebs-csi-controller`, `ebs-csi-node`, `hubble-relay`, and `hubble-ui`. None has an ArgoCD-owned chart to hold its own `templates/network-policy.yaml`.

For how `CiliumNetworkPolicy` enforcement works, and why these policies live here, see [How Network Policies Work](/docs/security/how-network-policies-work/#avoiding-a-lockout).

## What's Inside

- **[templates/](templates/)**: one `CiliumNetworkPolicy` per component. `ebs-csi-controller`'s EBS API egress and `karpenter`'s EC2 Fleet, SQS, and IAM egress are scoped via `toCIDR` to `vpcEndpointCidrs`, not `toEntities: world`
- **[templates/network-policy-shared-egress.yaml](templates/network-policy-shared-egress.yaml)**: namespace-wide kube-apiserver and coredns egress for every pod in `kube-system`, including `aws-load-balancer-controller` (deployed by [`aws-lbc`](../../aws-lbc)) and the catalog's `cilium-cep-restart` hook `Job`
- **[values.yaml](values.yaml)**: see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects the values the catalog injects via `appParams` when empty, so a missing injection fails the render
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass

## Values

### Network Policy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| vpcEndpointCidrs | object | see values.yaml | VPC interface endpoint IPs (`ec2`, `sqs`, `iam`) that `ebs-csi-controller` and `karpenter` egress is scoped to. Injected by the catalog via `appParams`. |

## Upstream Dependencies

- **[`units/eks/addons/cilium`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/cilium)** (catalog): deploys Cilium itself, and so the `CiliumNetworkPolicy` CRD, before ArgoCD ever syncs
