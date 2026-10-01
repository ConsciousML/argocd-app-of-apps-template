# `alloy` Helm Chart Reference

The [`alloy` chart](./) deploys [Grafana Alloy](https://grafana.com/docs/alloy/latest/) via the upstream `alloy` chart, as a DaemonSet collecting and forwarding pod logs and Kubernetes cluster events to [Loki](../loki/). [Values](#values) lists only what this chart sets. For every other key, read the upstream [`values.yaml`](https://github.com/grafana/alloy/blob/main/operations/helm/charts/alloy/values.yaml).

## What's Inside

- **[templates/network-policy.yaml](templates/network-policy.yaml)**: the DaemonSet's `CiliumNetworkPolicy`
- **[values.yaml](values.yaml)**: see [Values](#values)

## Values

### Alloy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy.alloy.resources | object | see values.yaml | Resource requests and limits. |
| alloy.alloy.configMap | object | see values.yaml | Alloy pipeline. Collects this node's pod logs and the cluster's events via the Kubernetes API, and pushes both to `loki-gateway`. |
| alloy.alloy.securityContext | object | see values.yaml | Runs as non-root UID and GID 473 with a read-only root filesystem. |
| alloy.alloy.mounts | object | see values.yaml | Mounts the `alloy-data` `emptyDir` (see `controller.volumes.extra`) at `/tmp/alloy`, the storage path. |

### Config Reloader

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy.configReloader | object | see values.yaml | Config reloader sidecar resources, and a non-root `securityContext` (UID and GID 65534). |

### DaemonSet

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alloy.global.podSecurityContext | object | see values.yaml | Pod-level `runAsNonRoot`, and `fsGroup` 473 so `alloy-data` is writable. |
| alloy.controller.type | string | `"daemonset"` | One Alloy pod per node. |
| alloy.controller.priorityClassName | string | `"daemonset-critical"` | Lets a pod preempt a lower-priority one on a full node. |
| alloy.controller.volumes | object | see values.yaml | The `alloy-data` `emptyDir`. |
| alloy.controller.tolerations | list | see values.yaml | Tolerates both Karpenter NodePool taints and the MNG taint, so every node runs a pod. |

## Upstream Dependencies

- **[`loki`](../loki/)**: receives logs at `loki-gateway`. Alloy retries failed writes, so Loki doesn't need to be up first
