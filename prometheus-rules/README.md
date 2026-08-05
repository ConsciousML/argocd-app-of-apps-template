# prometheus-rules

Standalone `PrometheusRule` manifests, one per component, for alerts not bundled by a Helm chart.

## What's Inside

- **[argocd.yaml](argocd.yaml)**: from [argo-cd-mixin](https://github.com/adinhodovic/argo-cd-mixin), the same mixin behind the `argocd` Grafana dashboards in `helm-kube-prometheus-stack/values.yaml`. Labeled `component: argocd` for Alertmanager's routing tree (see `helm-kube-prometheus-stack/values.yaml`).
- **[alloy.yaml](alloy.yaml)**: the `alloy_controller` group from [alloy-mixin](https://github.com/grafana/alloy/tree/main/operations/alloy-mixin), component-health alerts for Alloy's own pipeline (clustering and OpenTelemetry groups excluded, unused here). Labeled `component: loki` to route alongside Loki's own alerts.
