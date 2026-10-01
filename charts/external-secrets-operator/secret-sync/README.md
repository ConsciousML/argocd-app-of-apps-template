<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/helm_charts/external-secrets-operator/secret-sync/. It is not meant to be read directly in this repository. -->

# `secret-sync` Helm Chart Reference

The [`secret-sync` chart](./) renders a generic `SecretStore` (backed by AWS Secrets Manager) plus an `ExternalSecret` that syncs specific keys from one AWS secret into a Kubernetes `Secret`. Each `*-secrets-values.yaml` file in this directory is one instance, loaded via `extraValueFiles` in [`apps/values.yaml`](../../../apps/values.yaml).

For setup steps, read [How to Pass a Secret to an App](/docs/applications/pass-a-secret-to-an-app/).

## What's Inside

- **[templates/secret-store.yaml](templates/secret-store.yaml)**: the `SecretStore`, synced one wave before the `ExternalSecret`, so it's deleted after it
- **[templates/external-secret.yaml](templates/external-secret.yaml)**: the `ExternalSecret`. Its empty `template.metadata` stops ESO from copying ArgoCD's tracking labels and annotations onto the target `Secret`
- **[values.yaml](values.yaml)**: empty defaults, see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects the values the catalog injects via `appParams` when empty, so a missing injection fails the render
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass
- **[alertmanager-secrets-values.yaml](alertmanager-secrets-values.yaml)**: syncs the Alertmanager Slack bot token. `remoteProperty` must match the `secret_data` key in the catalog's `units/eks/addons/prometheus_stack/alertmanager/aws_secret_slack_bot`
- **[argocd-secrets-values.yaml](argocd-secrets-values.yaml)**: syncs the ArgoCD admin password hash. Uses `targetCreationPolicy: Merge`, since `argocd-secret` is also managed by ArgoCD itself
- **[grafana-secrets-values.yaml](grafana-secrets-values.yaml)**: syncs the Grafana admin password. Also sets `kube-prometheus-stack.grafana.admin.existingSecret` and `passwordKey`, consumed by `kube-prometheus-stack` through the same `extraValueFiles` entry so both charts agree on the target secret name
- **[tailscale-secrets-values.yaml](tailscale-secrets-values.yaml)**: syncs the Tailscale operator's OAuth client credentials

## Values

### AWS Source

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| secretStoreName | string | `""` | `SecretStore` name. Injected per instance by the catalog via `appParams`. |
| awsRegion | string | `""` | AWS region of the Secrets Manager secret. Injected per instance by the catalog via `appParams`. |
| remoteKey | string | `""` | Secrets Manager secret name, the `secret_name` output of the catalog unit creating it. Injected per instance by the catalog via `appParams`. |

### Target Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | `ExternalSecret` name. |
| targetSecretName | string | `""` | Kubernetes `Secret` to write. |
| targetCreationPolicy | string | `Merge` when empty | `Owner` creates and owns the `Secret`. `Merge` writes into an existing one. |
| refreshPolicy | string | `CreatedOnce` when empty | `CreatedOnce` syncs once. `Periodic` keeps polling, for rotated secrets. |
| data | list | `[]` | Keys to sync, each a `secretKey` in the target `Secret` and a `remoteProperty` in the AWS secret's JSON. |

## Upstream Dependencies

- **[`app_of_apps`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl)** (catalog): injects the [AWS Source](#aws-source) values via `appParams`
- **[`external-secrets-operator`](../operator)**: installs the `SecretStore` and `ExternalSecret` CRDs and reconciles them
