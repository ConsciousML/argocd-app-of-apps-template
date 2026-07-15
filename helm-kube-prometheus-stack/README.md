# helm-kube-prometheus-stack

Deploys [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) (Prometheus, Alertmanager, Grafana, and their operator) via the upstream chart.

## What's Inside

Grafana's admin credentials come from `grafana-secrets`, an instance of [`helm-eso-secret-sync`](../helm-eso-secret-sync). This app loads `helm-eso-secret-sync/grafana-secrets-values.yaml` directly via `extraValueFiles` in [`apps/values.yaml`](../apps/values.yaml), on top of its own `values.yaml`, so `admin.existingSecret` and `passwordKey` here stay in sync with `targetSecretName` and `secretKey` over there without duplicating the string.

`fullnameOverride` only pins this chart's own resources, the `prometheus`, `alertmanager`, and operator objects. Grafana, `kube-state-metrics`, and `node-exporter` are bundled subcharts that derive their own resource names from the Helm release name instead. Anything that references those names, like a `helm-httproute` `backendRef`, must match `tool.helm.releaseName` in `apps/values.yaml` or it silently points at the wrong Service.

> **Note**: several settings here are dev-only. `defaultRules.disabled.KubeCPUOvercommit` is turned off because this node group intentionally runs 2 nodes and the rule can't tell EKS has no control-plane node label. `persistentVolumeClaimRetentionPolicy.whenDeleted: Delete` reclaims volumes for cost savings. Neither should carry over to staging or prod.

## Integration

- **[`prometheus_stack`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/prometheus_stack)** (catalog): `grafana/aws_secret_password` generates the admin password that `grafana-secrets` syncs in
- **[`storage-class-gp3`](../storage-class-gp3)**: provisions the `gp3` `StorageClass` both `prometheus` and `alertmanager` request for their persistent volumes
