<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/helm_charts/app-of-apps/. It is not meant to be read directly in this repository. -->

# `apps` Helm Chart Reference

The [`apps` chart](./) implements the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative). It renders one ArgoCD `Application` per entry under `applications`.

For setup steps, read [How to Add, Edit, or Remove an App](/docs/applications/add-edit-or-remove-an-app/) and [Configure an App per Environment](/docs/applications/configure-an-app-per-environment/).

## What's Inside

- **[templates/applications.yaml](templates/applications.yaml)**: one `Application` per `applications` entry
- **[values.yaml](values.yaml)**: every application entry, with its dependency chain in comments, see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects an empty `config.spec.source.repoURL` or `global.environment`
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass

## Values

### Source

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.spec.destination.server | string | `"https://kubernetes.default.svc"` | Cluster every child `Application` deploys to. |
| config.spec.source.repoURL | string | `""` | This repository's URL, for every child `Application`. Set by the catalog from `github.hcl`. Must not be empty. |
| config.spec.source.targetRevision | string | `"main"` | Git revision every child `Application` syncs. Set by the catalog. |

### Catalog Inputs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| appParams | object | `{}` | Values injected per application, keyed by `name`, as the child `Application`'s `spec.source.helm.values`. Set by the catalog's `app_of_apps` unit. |
| global.environment | string | `""` | Deploying environment (`dev`, `staging`, or `prod`), rendered into `extraValueFiles` entries to pick a `values-<env>.yaml` overlay. Set by the catalog. Must not be empty. |

### Applications

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| applications | list | see values.yaml | One child `Application` per entry. See [Values Schema](#values-schema). |

## Values Schema

Each entry under `applications` accepts:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| applications[].name | string | none | Required. The `Application` name and, unless `path` is set, the source path in this repository. |
| applications[].path | string | `name` | Source path, when it differs from `name`. Used when multiple applications share a chart, like the `charts/gateway-api/httproute` instances. |
| applications[].destination.namespace | string | `name` | Target namespace. |
| applications[].syncWave | int | unset | Sets the `argocd.argoproj.io/sync-wave` annotation, controlling apply order relative to other applications. See the comments in `values.yaml` for the current dependency chain. |
| applications[].extraValueFiles | list | `[]` | Paths to additional Helm values files, loaded through a second `source` entry referenced via `$values`. Each entry is rendered with `tpl`, so it can reference `.Values.global.environment` to pick a per-environment overlay, like `loki`'s `values-{{ .Values.global.environment }}.yaml`. Also used to share values between a chart instance and a related one, like `kube-prometheus-stack` pulling in `secret-sync`'s Grafana secret name. |
| applications[].tool.helm.releaseName | string | unset | Pins the Helm release name. Several instances rely on this to match a Pod Identity association's expected `ServiceAccount` name or a catalog-side Terraform local. See the comments beside each entry in `values.yaml` for specifics. |
| applications[].syncOptions | list | `[]` | Extra entries appended to `syncPolicy.syncOptions`, alongside the default `CreateNamespace=false`. |
| applications[].preventCascadeDelete | bool | `false` | When `true`, drops the cascade-delete finalizer and sets `automated.prune: false`, so this app can never delete a resource it manages. Only set for apps owning cluster-scoped resources like `Namespace`, where deleting the app must not delete everything inside them. |
| applications[].finalizers | list | `[]` | Extra finalizers appended alongside the default `resources-finalizer.argocd.argoproj.io`. |
| applications[].project | string | `"default"` | ArgoCD project. |
| applications[].namespace | string | `"argocd"` | Namespace of the `Application` itself. |

## Upstream Dependencies

- **[`argocd_app_of_apps` module](https://github.com/ConsciousML/eks-forge-catalog/tree/main/modules/argocd_app_of_apps)** (catalog): provisions the root `Application` that points at this chart and sets `appParams`
