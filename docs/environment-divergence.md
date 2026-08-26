# Environment Divergence

How to give a chart a different config in dev, staging, or prod without duplicating its whole `values.yaml` per environment.

## Diverging a Chart's Values

Keep shared config in the chart's own `values.yaml`. Add one `extraValueFiles` entry to that app's entry in [`apps/values.yaml`](../apps/values.yaml):

```yaml
extraValueFiles:
  - charts/<group>/<chart>/values-{{ .Values.global.environment }}.yaml
```

Then add a `values-dev.yaml`, `values-staging.yaml`, or `values-prod.yaml` next to that chart's `values.yaml`, one per environment that actually diverges, holding only the keys that differ. An environment with nothing to override needs no file, it falls through to the chart's own `values.yaml`.

Document the new `extraValueFiles` entry in that chart's README.

See [`charts/monitoring/loki`](../charts/monitoring/loki) for a working example: `values-dev.yaml` and `values-staging.yaml` both reclaim its PVCs for cost savings, `values-prod.yaml` retains them.

## No Divergence Needed

Most apps need nothing here. If a chart behaves the same everywhere, skip `extraValueFiles` entirely.

## Implementation Details

`global.environment` is not set in this repo. The catalog ([terragrunt-template-catalog-eks](https://github.com/ConsciousML/terragrunt-template-catalog-eks)) injects it as a Helm value on the root `Application`, see `units/eks/addons/argocd/app_of_apps/terragrunt.hcl` there. `apps/values.yaml` defaults it to an empty string so a bare `helm template` still renders.

Each `extraValueFiles` entry in [`apps/templates/applications.yaml`](../apps/templates/applications.yaml) is rendered through Helm's `tpl` function, so an entry that's a plain string in `apps/values.yaml` can still reference `.Values.global.environment`.
