<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/helm_charts/external-secrets-operator/operator/. It is not meant to be read directly in this repository. -->

# `external-secrets-operator` Helm Chart Reference

The [`external-secrets-operator` chart](./) deploys the [External Secrets Operator](https://external-secrets.io/latest/) controller and CRDs (`SecretStore`, `ExternalSecret`) via the upstream `external-secrets` chart. [Values](#values) lists only what this chart sets. For every other key, read the upstream [`values.yaml`](https://github.com/external-secrets/external-secrets/blob/main/deploy/charts/external-secrets/values.yaml).

For setup steps, read [How to Pass a Secret to an App](/docs/applications/pass-a-secret-to-an-app/).

## What's Inside

- **[Chart.yaml](Chart.yaml)**: vendors the upstream chart. See its entry in [`apps/values.yaml`](../../../apps/values.yaml) for the `tool.helm.releaseName` pin
- **[templates/network-policy-controller.yaml](templates/network-policy-controller.yaml)**, **[templates/network-policy-webhook.yaml](templates/network-policy-webhook.yaml)**, and **[templates/network-policy-cert-controller.yaml](templates/network-policy-cert-controller.yaml)**: one `CiliumNetworkPolicy` per controller. The controller's egress to the Secrets Manager API is scoped via `toCIDR` to `vpcEndpointCidrs.secretsmanager`, not `toEntities: world`
- **[values.yaml](values.yaml)**: see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects the values the catalog injects via `appParams` when empty, so a missing injection fails the render
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass

## Values

### Network Policy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| vpcEndpointCidrs.secretsmanager | list | `[]` | Secrets Manager VPC interface endpoint IPs the controller's network policy allows egress to. Injected by the catalog via `appParams`. |

### Controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| external-secrets.serviceMonitor | object | `{"enabled":true}` | Enables the Prometheus `ServiceMonitor`. |
| external-secrets.resources | object | see values.yaml | Controller resource requests and limits. |
| external-secrets.podSecurityContext | object | see values.yaml | Sets `runAsNonRoot` at the pod level, also on `webhook` and `certController`. |
| external-secrets.nodeSelector | object | see values.yaml | Pins the controller to the `elastic` NodePool, with a matching `tolerations` entry. `webhook` and `certController` set the same. |

### Webhook

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| external-secrets.webhook.resources | object | see values.yaml | Webhook resource requests and limits. |

### Cert Controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| external-secrets.certController.resources | object | see values.yaml | Cert controller resource requests and limits. |

## Upstream Dependencies

- **[`external_secrets_operator`](https://github.com/ConsciousML/eks-forge-catalog/tree/main/units/eks/addons/external_secrets_operator)** (catalog): provisions the IAM role this controller's service account assumes via Pod Identity, scoped to secrets prefixed with the environment name
