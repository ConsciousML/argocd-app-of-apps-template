<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/helm_charts/monitoring/kube-prometheus-stack/. It is not meant to be read directly in this repository. -->

# `kube-prometheus-stack` Helm Chart Reference

The [`kube-prometheus-stack` chart](./) deploys [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) (Prometheus, Alertmanager, Grafana, and their operator) via the upstream chart. [Values](#values) lists only what this chart sets. For every other key, read the upstream [`values.yaml`](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml).

For per-environment overrides, read [Configure an App per Environment](/docs/applications/configure-an-app-per-environment/).

## What's Inside

- **`templates/network-policy-*.yaml`**: one `CiliumNetworkPolicy` per component ([prometheus](templates/network-policy-prometheus.yaml), [alertmanager](templates/network-policy-alertmanager.yaml), [grafana](templates/network-policy-grafana.yaml), [operator](templates/network-policy-operator.yaml), [kube-state-metrics](templates/network-policy-kube-state-metrics.yaml))
- **[values.yaml](values.yaml)**: see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects the values the catalog injects via `appParams` when empty, so a missing injection fails the render
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass
- **[values-dev.yaml](values-dev.yaml)** and **[values-staging.yaml](values-staging.yaml)**: delete the Prometheus and Alertmanager PVCs on StatefulSet delete, retain them on scale-down
- **[values-prod.yaml](values-prod.yaml)**: retains the Prometheus and Alertmanager PVCs on StatefulSet delete and scale-down
- **[`secret-sync/grafana-secrets-values.yaml`](../../external-secrets-operator/secret-sync/grafana-secrets-values.yaml)**: loaded by this app via `extraValueFiles` in [`apps/values.yaml`](../../../apps/values.yaml), sets `grafana.admin.existingSecret` and `passwordKey` to the `Secret` that `grafana-secrets` syncs

## Values

### Release

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-prometheus-stack.fullnameOverride | string | `""` | Names this chart's own resources. Must match `tool.helm.releaseName` in `apps/values.yaml`. Injected by the catalog via `appParams`. |
| kube-prometheus-stack.environment | string | `""` | Environment name, prefixes each Slack channel in `alertmanager.config`. Injected by the catalog via `appParams`. |
| kube-prometheus-stack.crds.enabled | bool | `false` | Disabled, the catalog's `prometheus_operator_crds` unit installs the CRDs before ArgoCD syncs. |
| kube-prometheus-stack.kubeEtcd | object | see values.yaml | Disabled with `kubeScheduler` and `kubeControllerManager`, AWS-managed on EKS. |

### Scheduling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-prometheus-stack.prometheus-node-exporter.priorityClassName | string | `"daemonset-critical"` | Lets a node-exporter pod preempt a lower-priority one on a full node. It tolerates both Karpenter NodePool taints and the MNG taint, so every node runs one. |
| kube-prometheus-stack.prometheus.prometheusSpec.resources | object | see values.yaml | Resource requests and limits. Every component sets its own. |
| kube-prometheus-stack.prometheus.prometheusSpec.nodeSelector | object | see values.yaml | Pins Prometheus to the `critical` NodePool, with a matching `tolerations` entry. Every component except node-exporter sets the same. |

### Alerting

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-prometheus-stack.defaultRules.additionalRuleGroupLabels | object | see values.yaml | `component` label per default rule group, which Alertmanager routes on. |

### Prometheus

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-prometheus-stack.prometheus.prometheusSpec.replicas | int | `2` | Prometheus replicas, each with its own PVC. Hard pod anti-affinity, spread across AZs, and a PDB keeping 1 up during disruption. |
| kube-prometheus-stack.prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues | bool | `false` | Picks up every `ServiceMonitor` regardless of labels. `podMonitorSelectorNilUsesHelmValues` and `ruleSelectorNilUsesHelmValues` do the same for `PodMonitor` and `PrometheusRule`. |
| kube-prometheus-stack.prometheus.prometheusSpec.storageSpec | object | see values.yaml | `gp3` PVC per replica. PVC retention is set per environment in `values-<env>.yaml`. |

### Alertmanager

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-prometheus-stack.alertmanager.alertmanagerSpec.replicas | int | `3` | Alertmanager replicas, each with its own `gp3` PVC. Hard pod anti-affinity, spread across AZs, and a PDB keeping a majority up. |
| kube-prometheus-stack.alertmanager.alertmanagerSpec.secrets | list | see values.yaml | Mounts the Slack bot token `Secret`. Must match `targetSecretName` in `secret-sync/alertmanager-secrets-values.yaml`. |
| kube-prometheus-stack.alertmanager.config | object | see values.yaml | Slack routing tree, one `<environment>-<component>-<severity>` channel per route. Unmatched alerts go to `<environment>-unrouted`. |

### Grafana

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| kube-prometheus-stack.grafana.additionalDataSources | list | see values.yaml | Adds Loki as a datasource. Prometheus stays the default. |
| kube-prometheus-stack.grafana.dashboards | object | see values.yaml | Addon dashboards (Karpenter, ExternalDNS, AWS Load Balancer Controller, External Secrets Operator, ArgoCD, Loki, and blackbox-exporter), each in its own folder from `dashboardProviders`. |
| kube-prometheus-stack.grafana.admin.existingSecret | string | `""` | Admin credentials `Secret`, with `passwordKey`. Both set by `secret-sync/grafana-secrets-values.yaml`, loaded via `extraValueFiles`. |

## Resource Names

`fullnameOverride` only names this chart's own resources: the `prometheus`, `alertmanager`, and operator objects. Grafana, `kube-state-metrics`, and `node-exporter` are bundled subcharts that derive their resource names from the Helm release name instead. Anything referencing those names, like an [`httproute`](../../gateway-api/httproute) `backendRef`, must match `tool.helm.releaseName` in `apps/values.yaml`, or it silently points at the wrong Service.

## Upstream Dependencies

- **[`prometheus_stack`](https://github.com/ConsciousML/eks-forge-catalog/tree/main/units/eks/addons/prometheus_stack)** (catalog): `grafana/aws_secret_password` generates the admin password that `grafana-secrets` syncs in
- **[`app_of_apps`](https://github.com/ConsciousML/eks-forge-catalog/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl)** (catalog): injects `fullnameOverride`, `environment`, and the Prometheus and Alertmanager `externalUrl` via `appParams`
- **[`storage-class-gp3`](../../../manifests/storage-class-gp3)**: provisions the `gp3` `StorageClass` both `prometheus` and `alertmanager` request for their persistent volumes
- **[`alertmanager-secrets`](../../external-secrets-operator/secret-sync/alertmanager-secrets-values.yaml)**: syncs the Slack bot token `Secret` Alertmanager mounts
