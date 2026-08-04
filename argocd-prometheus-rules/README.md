# argocd-prometheus-rules

A `PrometheusRule` with alerting rules from [argo-cd-mixin](https://github.com/adinhodovic/argo-cd-mixin), the same mixin behind the `argocd` Grafana dashboards in `helm-kube-prometheus-stack/values.yaml`.

## What's Inside

- **[prometheus-rule.yaml](prometheus-rule.yaml)**: each alert is labeled `component: argocd` for Alertmanager's routing tree (see `helm-kube-prometheus-stack/values.yaml`).
