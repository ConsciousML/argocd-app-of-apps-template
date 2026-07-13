# helm-karpenter-config

Deploys Karpenter's `EC2NodeClass` and `NodePool`, defining which EC2 instances Karpenter can provision and the constraints it provisions them under.

## Integration

- **[`units/eks/addons/karpenter/iam`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/karpenter/iam)** (catalog): provisions the node IAM role this chart's `nodeRole` value points at
- **[`helm-karpenter`](../helm-karpenter)**: depends on the controller and CRDs this chart's `EC2NodeClass` and `NodePool` rely on
