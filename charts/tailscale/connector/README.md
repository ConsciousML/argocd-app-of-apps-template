# tailscale-connector

Deploys a Tailscale [`Connector`](https://tailscale.com/kb/1441/kubernetes-operator-connector) advertising the VPC CIDR as a subnet route, giving Tailnet devices routed access to private VPC resources.

## Upstream Dependencies

- **[`app_of_apps`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl)** (catalog): injects `name`, `hostnamePrefix`, and `advertiseRoutes` from the EKS cluster name and the VPC CIDR
- **[`tailscale-operator`](../operator)**: this chart's `Connector` CRD is installed by the operator, synced before this chart
