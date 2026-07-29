# helm-karpenter-config

Deploys Karpenter's `EC2NodeClass` and `NodePool`, defining which EC2 instances Karpenter can provision and the constraints it provisions them under.

## Upstream Dependencies

- **[`units/eks/addons/karpenter/iam`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/karpenter/iam)** (catalog): provisions the node IAM role this chart's `nodeRole` value points at (see [values.yaml](values.yaml) for `clusterName`)
- **[`units/eks/addons/karpenter/helm`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/karpenter/helm)** (catalog): deploys the controller and CRDs this chart's `EC2NodeClass` and `NodePool` rely on
