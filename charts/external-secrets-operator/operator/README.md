# external-secrets-operator

Deploys the [External Secrets Operator](https://external-secrets.io/latest/) controller and CRDs (`SecretStore`, `ExternalSecret`) via the upstream `external-secrets` chart.

## What's Inside

- **[Chart.yaml](Chart.yaml)**: vendors the upstream chart. See its entry in [`apps/values.yaml`](../../../apps/values.yaml) for the `tool.helm.releaseName` pin
- **[values.yaml](values.yaml)**: enables the controller's `serviceMonitor`; `vpcEndpointCidrs.secretsmanager` is a placeholder injected by the catalog's `app_of_apps` unit via `appParams.external-secrets-operator`
- **[templates/network-policy-controller.yaml](templates/network-policy-controller.yaml)**, **[templates/network-policy-webhook.yaml](templates/network-policy-webhook.yaml)**, and **[templates/network-policy-cert-controller.yaml](templates/network-policy-cert-controller.yaml)**: one `CiliumNetworkPolicy` per controller. The controller's egress to the Secrets Manager API is scoped via `toCIDR` to the pinned VPC interface endpoint IPs in `vpcEndpointCidrs.secretsmanager`, not `toEntities: world`

## Upstream Dependencies

- **[`external_secrets_operator`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/external_secrets_operator)** (catalog): provisions the IAM role this controller's service account assumes via Pod Identity, scoped to secrets prefixed with the environment name
