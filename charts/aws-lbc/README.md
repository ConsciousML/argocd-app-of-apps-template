# aws-lbc

Deploys the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/), which provisions ALBs from `Ingress` and `Gateway` resources.

## What's Inside

- **[Chart.yaml](Chart.yaml)**: dependency version must stay in sync with `local.version_aws_lbc` in the catalog's `terragrunt.stack.hcl`
- **[values.yaml](values.yaml)**: `clusterName`, `region`, `vpcId`, and `vpcEndpointCidrs` are placeholders. The catalog's [`app_of_apps` unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl) injects the real values via `appParams.aws-lbc` at sync time
- **[templates/network-policy.yaml](templates/network-policy.yaml)**: `CiliumNetworkPolicy` for the controller. Egress to the ELBv2/EC2/ResourceGroupsTaggingAPI/Shield/ACM APIs is scoped via `toCIDR` to the pinned VPC interface endpoint IPs in `vpcEndpointCidrs`, not `toEntities: world`

The chart bundles its own copy of the Gateway API CRDs. [`crds-aws-lbc-gateway-api`](../../manifests/crds/aws-lbc-gateway-api) installs them again separately so dependents can target the CRDs without depending on this controller.

## Upstream Dependencies

- **[`aws_load_balancer_controller`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/aws_load_balancer_controller)** (catalog): provisions the IAM role this controller's service account assumes via Pod Identity. See this app's entry in [`apps/values.yaml`](../../apps/values.yaml) for the `tool.helm.releaseName` pin that keeps the Helm release name matching that service account
