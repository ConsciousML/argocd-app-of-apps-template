# tailscale-operator

Deploys the [Tailscale Kubernetes operator](https://tailscale.com/kb/1236/kubernetes-operator) via the upstream `tailscale-operator` chart, unmodified.

## Upstream Dependencies

- **[`external_secrets_operator`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/external_secrets_operator)** (catalog): provisions the IAM role ESO's service account assumes, needed before ESO can sync this operator's OAuth credentials
- **[`tailscale-secrets`](../../external-secrets-operator/secret-sync/tailscale-secrets-values.yaml)**: syncs the OAuth client credentials into the `operator-oauth` secret this operator expects, synced before this chart
- **[`units/tailscale`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/tailscale)** (catalog): provisions the WIF credential and GitHub secrets CI uses to authenticate to Tailscale when deploying this chart
