# cilium

[Cilium](https://cilium.io/) with [Hubble](https://docs.cilium.io/en/stable/observability/hubble/), for network flow visibility.

## What's Inside

- **[values.yaml](values.yaml)**: `k8sServiceHost` and `k8sServicePort` are placeholders. The catalog's [`app_of_apps` unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl) injects the real values via `appParams.cilium` at sync time
- **`hubble-ui-httproute`** (app-of-apps): an instance of the generic [`httproute`](https://github.com/ConsciousML/argocd-app-of-apps-template/tree/main/charts/gateway-api/httproute) chart, exposes the Hubble UI
