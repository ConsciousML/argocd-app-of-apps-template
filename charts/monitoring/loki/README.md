# loki

Deploys [Loki](https://grafana.com/docs/loki/latest/) via the upstream `loki` chart, monolithic mode with S3 storage.

## What's Inside

- **[values.yaml](values.yaml)**: monolithic deployment mode, S3 storage, resource sizing
- **`templates/network-policy-*.yaml`**: one `CiliumNetworkPolicy` per component ([single-binary](templates/network-policy-single-binary.yaml), [gateway](templates/network-policy-gateway.yaml), [canary](templates/network-policy-canary.yaml), [chunks-cache](templates/network-policy-chunks-cache.yaml), [results-cache](templates/network-policy-results-cache.yaml))

## Upstream Dependencies

- **[`units/eks/addons/loki`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/loki)** (catalog): provisions the two S3 buckets `loki.loki.storage.bucketNames` points at (see [values.yaml](values.yaml) for how it's injected), and the Pod Identity association the `releaseName` in [`apps/values.yaml`](../../../apps/values.yaml) must match
