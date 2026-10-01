# `aws-lbc` Helm Chart Reference

The [`aws-lbc` chart](./) deploys the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) via the upstream `aws-load-balancer-controller` chart. It provisions ALBs from `Ingress` and `Gateway` resources. [Values](#values) lists only what this chart sets. For every other key, read the upstream [`values.yaml`](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/values.yaml).

## What's Inside

- **[Chart.yaml](Chart.yaml)**: dependency version must stay in sync with `local.version_aws_lbc` in the catalog's `terragrunt.stack.hcl`
- **[templates/network-policy.yaml](templates/network-policy.yaml)**: the controller's `CiliumNetworkPolicy`. Egress to the ELBv2, EC2, Resource Groups Tagging, Shield, and ACM APIs is scoped via `toCIDR` to `vpcEndpointCidrs`, not `toEntities: world`
- **[values.yaml](values.yaml)**: see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects the values the catalog injects via `appParams` when empty, so a missing injection fails the render
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass

## Values

### Network Policy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| vpcEndpointCidrs | object | see values.yaml | VPC interface endpoint IPs (`ec2`, `elasticloadbalancing`, `tagging`, `shield`, `acm`) the network policy allows egress to. Injected by the catalog via `appParams`. |

### AWS Load Balancer Controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aws-load-balancer-controller.clusterName | string | `""` | EKS cluster name. Injected by the catalog via `appParams`. |
| aws-load-balancer-controller.region | string | `""` | AWS region. Injected by the catalog via `appParams`. |
| aws-load-balancer-controller.vpcId | string | `""` | VPC ID. Injected by the catalog via `appParams`. |
| aws-load-balancer-controller.enableServiceMutatorWebhook | bool | `false` | Disables the webhook that mutates `Service` resources of type `LoadBalancer`. |
| aws-load-balancer-controller.serviceMonitor | object | `{"enabled":true}` | Enables the Prometheus `ServiceMonitor`. |

### Scheduling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aws-load-balancer-controller.nodeSelector | object | see values.yaml | Pins pods to the `elastic` NodePool, with a matching `tolerations` entry. |
| aws-load-balancer-controller.resources | object | see values.yaml | Resource requests and limits. |

## Gateway API CRDs

<!-- MIGRATE: explanation, move to the site's explanation docs -->
The chart bundles its own copy of the Gateway API CRDs. [`crds-aws-lbc-gateway-api`](../../manifests/crds/aws-lbc-gateway-api) installs them again separately, so dependents can target the CRDs without depending on this controller.

## Upstream Dependencies

- **[`aws_load_balancer_controller`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/aws_load_balancer_controller)** (catalog): provisions the IAM role this controller's service account assumes via Pod Identity. See this app's entry in [`apps/values.yaml`](../../apps/values.yaml) for the `tool.helm.releaseName` pin that keeps the Helm release name matching that service account
