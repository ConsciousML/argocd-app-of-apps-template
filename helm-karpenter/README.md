# helm-karpenter

Deploys the [Karpenter](https://karpenter.sh/) controller via the upstream `karpenter` chart, unmodified.

## Integration

- **[`units/eks/addons/karpenter/iam`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/karpenter/iam)** (catalog): provisions the controller IAM role and interruption queue this chart's `karpenter.settings` values point at, and the Pod Identity association the `releaseName` in [`apps/values.yaml`](../apps/values.yaml) must match
- **[`helm-karpenter-config`](../helm-karpenter-config)**: depends on the `EC2NodeClass` and `NodePool` CRDs this chart installs
