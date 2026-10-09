<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/helm_charts/right-sizing/vpa/. It is not meant to be read directly in this repository. -->

# `vpa` Helm Chart Reference

The [`vpa` chart](./) deploys a recommender-only Kubernetes [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) via the upstream Fairwinds `vpa` chart, the source data for [Goldilocks](../goldilocks/). It only writes recommendations to each `VerticalPodAutoscaler`'s `status`. It never evicts or resizes running pods. [Values](#values) lists only what this chart sets. For every other key, read the upstream [`values.yaml`](https://github.com/FairwindsOps/charts/blob/master/stable/vpa/values.yaml).

## What's Inside

- **[templates/network-policy.yaml](templates/network-policy.yaml)**: the recommender's `CiliumNetworkPolicy`
- **[values.yaml](values.yaml)**: see [Values](#values)

## Values

### Recommender

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| vpa.recommender.extraArgs | object | see values.yaml | Recommender flags: CPU at p90 and memory at p99, history backfilled from kube-prometheus-stack's Prometheus. |
| vpa.recommender.podMonitor | object | `{"enabled":true}` | Enables the Prometheus `PodMonitor`. |
| vpa.recommender.resources | object | see values.yaml | Resource requests and limits. |
| vpa.recommender.nodeSelector | object | see values.yaml | Pins the recommender to the `elastic` NodePool, with a matching `tolerations` entry. |

### Disabled Components

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| vpa.updater.enabled | bool | `false` | Disabled, so running pods are never evicted. |
| vpa.admissionController.enabled | bool | `false` | Disabled, so pods are never resized at admission. |
| vpa.metrics-server.enabled | bool | `false` | Disabled, metrics-server is the EKS addon instead. |

## Upstream Dependencies

- **EKS `metrics-server` addon** ([eks-forge-catalog](https://github.com/ConsciousML/eks-forge-catalog)): the recommender hard-depends on it for live resource usage
- **[`kube-prometheus-stack`](../../monitoring/kube-prometheus-stack)**: Prometheus backfills the recommender's history at startup. Non-fatal if not ready yet
