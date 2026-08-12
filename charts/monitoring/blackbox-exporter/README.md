# blackbox-exporter

Deploys [blackbox-exporter](https://github.com/prometheus/blackbox_exporter) via the upstream `prometheus-blackbox-exporter` chart, probing every private and public tool endpoint for HTTP reachability.

## Upstream Dependencies

- **[`units/eks/addons/argocd/app_of_apps`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/argocd)** (catalog): injects `serviceMonitor.targets` (see [values.yaml](values.yaml)) from [`domains.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/pipelines/dev/eks/domains.hcl)
