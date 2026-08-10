# prometheus-rules

Standalone `PrometheusRule` manifests, one per component, for alerts not bundled by a Helm chart.

## What's Inside

- **[argocd.yaml](argocd.yaml)**: from [argo-cd-mixin](https://github.com/adinhodovic/argo-cd-mixin), the same mixin behind the `argocd` Grafana dashboards in `kube-prometheus-stack/values.yaml`. Labeled `component: argocd` for Alertmanager's routing tree (see `kube-prometheus-stack/values.yaml`).
- **[alloy.yaml](alloy.yaml)**: the `alloy_controller` group from [alloy-mixin](https://github.com/grafana/alloy/tree/main/operations/alloy-mixin), component-health alerts for Alloy's own pipeline (clustering and OpenTelemetry groups excluded, unused here). Labeled `component: loki` to route alongside Loki's own alerts.
- **[karpenter.yaml](karpenter.yaml)**: the `karpenter` group from [kubernetes-autoscaling-mixin](https://github.com/adinhodovic/kubernetes-autoscaling-mixin), verified against the pinned Karpenter chart version's metrics (`version_karpenter_helm` in the catalog repo). Labeled `component: k8s`, Karpenter is core node-provisioning infra.
- **[keda.yaml](keda.yaml)**: the mixin's `keda` group, fully commented out and applies no resource. KEDA isn't deployed here, kept as a ready reference if it's ever adopted.
