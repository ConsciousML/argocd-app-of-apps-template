# helm-karpenter

Deploys the [Karpenter](https://karpenter.sh/) controller via the upstream `karpenter` chart, unmodified.

## Upstream Dependencies

- **[`units/eks/addons/karpenter/iam`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/karpenter/iam)** (catalog): provisions the controller IAM role and interruption queue `karpenter.settings.interruptionQueue` points at (see [values.yaml](values.yaml) for how it's injected), and the Pod Identity association the `releaseName` in [`apps/values.yaml`](../apps/values.yaml) must match
- **[`helm-kube-prometheus-stack`](../helm-kube-prometheus-stack)**: `karpenter.serviceMonitor.enabled` here needs the `ServiceMonitor` CRD that chart installs, so this app syncs after it in [`apps/values.yaml`](../apps/values.yaml)
