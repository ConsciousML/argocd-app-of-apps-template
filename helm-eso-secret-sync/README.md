# helm-eso-secret-sync

Generic `SecretStore` (backed by AWS Secrets Manager) plus an `ExternalSecret` that syncs specific keys from one AWS secret into a Kubernetes `Secret`.

## What's Inside

Each `*-secrets-values.yaml` file is loaded via `extraValueFiles` in [`apps/values.yaml`](../apps/values.yaml) and is one instance.

- **[argocd-secrets-values.yaml](argocd-secrets-values.yaml)**: uses `targetCreationPolicy: Merge`, since `argocd-secret` is also managed by ArgoCD itself
- **[grafana-secrets-values.yaml](grafana-secrets-values.yaml)**: also sets `kube-prometheus-stack.grafana.admin.existingSecret` and `passwordKey`, consumed by `helm-kube-prometheus-stack` through the same `extraValueFiles` entry so both charts agree on the target secret name
- **[tailscale-secrets-values.yaml](tailscale-secrets-values.yaml)**: syncs the Tailscale operator's OAuth client credentials

## Integration

- **[`app_of_apps`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl)** (catalog): injects `secretStoreName`, `awsRegion`, and each instance's `remoteKey` via `appParams`
