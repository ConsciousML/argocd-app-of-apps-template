# `loki` Helm Chart Reference

The [`loki` chart](./) deploys [Loki](https://grafana.com/docs/loki/latest/) via the upstream `loki` chart, in monolithic mode with S3 storage. [Values](#values) lists only what this chart sets. For every other key, read the upstream [`values.yaml`](https://github.com/grafana-community/helm-charts/blob/main/charts/loki/values.yaml).

For per-environment overrides, read [Configure an App per Environment](https://eks-forge.readthedocs.io/latest/docs/applications/configure-an-app-per-environment/).

## What's Inside

- **`templates/network-policy-*.yaml`**: one `CiliumNetworkPolicy` per component ([single-binary](templates/network-policy-single-binary.yaml), [gateway](templates/network-policy-gateway.yaml), [canary](templates/network-policy-canary.yaml), [chunks-cache](templates/network-policy-chunks-cache.yaml), [results-cache](templates/network-policy-results-cache.yaml))
- **[values.yaml](values.yaml)**: see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects the values the catalog injects via `appParams` when empty, so a missing injection fails the render
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass
- **[values-dev.yaml](values-dev.yaml)** and **[values-staging.yaml](values-staging.yaml)**: delete the `singleBinary` PVCs on StatefulSet delete and scale-down
- **[values-prod.yaml](values-prod.yaml)**: retains the `singleBinary` PVCs on StatefulSet delete and scale-down

## Values

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| loki.deploymentMode | string | `"Monolithic"` | Monolithic mode, every Loki component in the `singleBinary` StatefulSet. The other modes' replicas are set to 0. |
| loki.minio.enabled | bool | `false` | Disabled, storage is S3. |

### Monitoring

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| loki.monitoring | object | see values.yaml | Enables the `ServiceMonitor` and the Loki mixin rules and alerts. Alerts carry `component: loki`, which Alertmanager routes on. |

### Loki Config

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| loki.loki.auth_enabled | bool | `false` | Single tenant, so writes need no `X-Scope-OrgID` header. |
| loki.loki.commonConfig.replication_factor | int | `3` | Each log stream is written to 3 replicas. |
| loki.loki.storage | object | see values.yaml | S3 `chunks` and `ruler` bucket names and region. Injected by the catalog via `appParams`. |
| loki.loki.limits_config | object | see values.yaml | 28-day retention, structured metadata, and the volume API. |

### Single Binary

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| loki.singleBinary.replicas | int | `3` | `singleBinary` StatefulSet replicas. |
| loki.singleBinary.topologySpreadConstraints | list | see values.yaml | Spreads replicas across AZs, `DoNotSchedule` when unsatisfiable. |
| loki.singleBinary.podDisruptionBudget.minAvailable | int | `2` | Keeps a majority up during voluntary disruption. |
| loki.singleBinary.resources | object | see values.yaml | Resource requests and limits. The caches, the gateway, the canary, and the sidecar set their own. |
| loki.singleBinary.nodeSelector | object | see values.yaml | Pins pods to the `critical` NodePool, with a matching `tolerations` entry. The caches and the gateway set the same. |
| loki.singleBinary.persistence.size | string | `"30Gi"` | PVC size per replica. PVC deletion is set per environment in `values-<env>.yaml`. |

### Caches

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| loki.chunksCache.allocatedMemory | int | `1024` | Chunks cache memory in MB, below the chart default of 8192. |

### Canary

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| loki.lokiCanary.priorityClassName | string | `"daemonset-critical"` | Lets a canary pod preempt a lower-priority one on a full node. It tolerates both Karpenter NodePool taints and the MNG taint, so every node runs one. |

## Upstream Dependencies

- **[`units/eks/addons/loki`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/loki)** (catalog): provisions the two S3 buckets `loki.loki.storage.bucketNames` points at, and the Pod Identity association the `releaseName` in [`apps/values.yaml`](../../../apps/values.yaml) must match
