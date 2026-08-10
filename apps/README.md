# apps

Helm chart implementing the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative). [`templates/applications.yaml`](templates/applications.yaml) renders one ArgoCD `Application` per entry under `applications` in [`values.yaml`](values.yaml).

## Values Schema

Each entry under `applications` accepts:

| Field | Description |
|---|---|
| **`name`** (required) | the `Application` name and, unless `path` is set, the source path in this repository |
| **`path`** | source path, when it differs from `name`. Used when multiple applications share a chart, like the `charts/gateway-api/httproute` instances |
| **`destination.namespace`** | target namespace, defaults to `name` |
| **`syncWave`** | sets the `argocd.argoproj.io/sync-wave` annotation, controlling apply order relative to other applications. See the comments in `values.yaml` for the current dependency chain |
| **`extraValueFiles`** | paths to additional Helm values files, loaded through a second `source` entry referenced via `$values`. Use this to share values between a chart instance and a related one, like `kube-prometheus-stack` pulling in `secret-sync`'s Grafana secret name |
| **`tool.helm.releaseName`** | pins the Helm release name. Several instances rely on this to match a Pod Identity association's expected `ServiceAccount` name or a catalog-side Terraform local. See the comments beside each entry in `values.yaml` for specifics |
| **`syncOptions`** | extra entries appended to `syncPolicy.syncOptions`, alongside the default `CreateNamespace=false` |
| **`preventCascadeDelete`** | when `true`, drops the cascade-delete finalizer and sets `automated.prune: false`, so this app can never delete a resource it manages. Only set for apps owning cluster-scoped resources like `Namespace`, where deleting the app must not delete everything inside them |
| **`finalizers`** | extra finalizers appended alongside the default `resources-finalizer.argocd.argoproj.io` |
| **`project`** | ArgoCD project, defaults to `default` |

`appParams.<name>` (top-level, sibling of `applications`) is injected as `spec.source.helm.values` on the matching `Application`. This is how the app-of-apps caller passes runtime values, like hostnames or secret keys, without editing this file. See [`../README.md`](../README.md) for how to add a new application entry.

## Upstream Dependencies

- **[`argocd_app_of_apps` module](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/modules/argocd_app_of_apps)** (catalog): provisions the root `Application` that points at this chart and sets `appParams`
