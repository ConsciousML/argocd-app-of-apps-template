<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/helm_charts/right-sizing/goldilocks/. It is not meant to be read directly in this repository. -->

# `goldilocks` Helm Chart Reference

The [`goldilocks` chart](./) deploys the [Goldilocks](https://goldilocks.docs.fairwinds.com/) dashboard via the upstream Fairwinds `goldilocks` chart. It reads `VerticalPodAutoscaler` recommendations and summarizes them per workload. [Values](#values) lists only what this chart sets. For every other key, read the upstream [`values.yaml`](https://github.com/FairwindsOps/charts/blob/master/stable/goldilocks/values.yaml).

## What's Inside

- **[templates/network-policy.yaml](templates/network-policy.yaml)**: the dashboard's `CiliumNetworkPolicy`
- **[values.yaml](values.yaml)**: see [Values](#values)
- **`goldilocks-httproute`** (app-of-apps): an instance of the generic [`httproute`](../../gateway-api/httproute) chart, exposes the dashboard

## Values

### Disabled Components

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| goldilocks.vpa.enabled | bool | `false` | Disabled, VPA is the separate [`vpa`](../vpa) chart. |
| goldilocks.metrics-server.enabled | bool | `false` | Disabled, metrics-server is the EKS addon instead. |

### Controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| goldilocks.controller.flags.on-by-default | string | `"true"` | Creates a VPA for every workload in every namespace, no namespace label needed. |
| goldilocks.controller.resources | object | see values.yaml | Resource requests and limits. |
| goldilocks.controller.nodeSelector | object | see values.yaml | Pins the controller to the `elastic` NodePool, with a matching `tolerations` entry. |
| goldilocks.controller.rbac.extraRules | list | see values.yaml | Read access to `alertmanagers` and `prometheuses` (`monitoring.coreos.com`). |

### Dashboard

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| goldilocks.dashboard.flags.on-by-default | string | `"true"` | Lists every namespace, not only labeled ones. |
| goldilocks.dashboard.resources | object | see values.yaml | Resource requests and limits. |
| goldilocks.dashboard.nodeSelector | object | see values.yaml | Pins the dashboard to the `elastic` NodePool, with a matching `tolerations` entry. |

## Upstream Dependencies

- **[`vpa`](../vpa/)**: the VPA recommender and CRD that Goldilocks reads recommendations from
- **EKS `metrics-server` addon** ([eks-forge-catalog](https://github.com/ConsciousML/eks-forge-catalog)): required by the VPA recommender, not by Goldilocks directly
