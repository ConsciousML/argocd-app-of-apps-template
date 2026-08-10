# external-secrets-operator

Deploys the [External Secrets Operator](https://external-secrets.io/latest/) controller and CRDs (`SecretStore`, `ExternalSecret`) via the upstream `external-secrets` chart, unmodified.

## What's Inside

- **[Chart.yaml](Chart.yaml)**: vendors the upstream chart with no value overrides. See its entry in [`apps/values.yaml`](../../../apps/values.yaml) for the `tool.helm.releaseName` pin

## Upstream Dependencies

- **[`external_secrets_operator`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/external_secrets_operator)** (catalog): provisions the IAM role this controller's service account assumes via Pod Identity, scoped to secrets prefixed with the environment name
