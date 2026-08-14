# cilium

[Cilium](https://cilium.io/) with [Hubble](https://docs.cilium.io/en/stable/observability/hubble/), for network flow visibility.

## What's Inside

- **[values.yaml](values.yaml)**: `k8sServiceHost` and `k8sServicePort` are placeholders. The catalog's [`app_of_apps` unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl) injects the real values via `appParams.cilium` at sync time
- **[templates/dynamic-metrics-configmap.yaml](templates/dynamic-metrics-configmap.yaml)**: Hubble metrics via the dynamic exporter (`hubble.metrics.dynamic.*` in `values.yaml`), so metric changes hot reload without a `cilium-agent` restart. `dns` and `http` are excluded. Both need the L7 proxy, which is off (`envoy.enabled: false`), and L7 visibility is a known limitation of `aws-cni` chaining mode
- **`hubble-ui-httproute`** (app-of-apps): an instance of the generic [`httproute`](https://github.com/ConsciousML/argocd-app-of-apps-template/tree/main/charts/gateway-api/httproute) chart, exposes the Hubble UI

## Querying Hubble Metrics

See the [Hubble metrics reference](https://docs.cilium.io/en/stable/observability/metrics/#hubble) for the full metric catalog, labels, and context options. Metric names in Prometheus are `hubble_` plus the reference's `Name` column (e.g. `flows_processed_total` is queried as `hubble_flows_processed_total`), the `hubble_` prefix isn't spelled out in the reference tables themselves.
