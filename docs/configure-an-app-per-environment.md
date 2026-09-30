{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

# How to Configure an App per Environment

This guide shows you how to give an app different Helm values in [`dev`](/docs/iac/#dev), [`staging`](/docs/iac/#staging), and [`prod`](/docs/iac/#prod), through [environment overlays](/docs/applications/how-the-app-of-apps-works/#environment-overlays). You need it when a setting must differ per environment (e.g. keeping Loki's volumes in `prod`, but deleting them elsewhere to save costs). Your app must be a Helm chart.

It's one of the [Extra Steps](/docs/applications/add-edit-or-remove-an-app/#extra-steps) of adding or editing an app, and assumes you've created a branch in your app of apps fork, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch). It needs no change in your catalog fork.

For a value that comes from an AWS resource or the catalog's configuration, see [Pass Terraform Values to an App](/docs/applications/pass-terraform-values-to-an-app/) instead.

## Add an Overlay per Environment

Next to your chart's `values.yaml`, add a `values-dev.yaml`, a `values-staging.yaml`, and a `values-prod.yaml`. Each holds only the keys that differ from `values.yaml`, with a comment on top saying why. If your chart wraps an upstream chart, nest the keys under the dependency's `name` from your `Chart.yaml`, as in `values.yaml`.

For example, Loki keeps its volumes in `prod`, in [`charts/monitoring/loki/values-prod.yaml`](../charts/monitoring/loki/values-prod.yaml):
```yaml
# Retains the singleBinary StatefulSet's PVCs on both delete and scale-down, unlike dev
# and staging.

loki:
  singleBinary:
    persistence:
      enableStatefulSetAutoDeletePVC: false
```

And deletes them in `dev`, in [`charts/monitoring/loki/values-dev.yaml`](../charts/monitoring/loki/values-dev.yaml), as in `staging`:
```yaml
# Reclaims the singleBinary StatefulSet's PVCs on both delete and scale-down, for cost
# savings. Dev and staging only, must not carry to prod.

loki:
  singleBinary:
    persistence:
      enableStatefulSetAutoDeletePVC: true
```

:::warning
Add all three files, even when an environment keeps the defaults. ArgoCD fails to sync an Application whose values file is missing. In that case, the file holds only a comment saying so.
:::

## Load the Overlays

Under your app's entry in [`apps/values.yaml`](../apps/values.yaml), add your overlay to `extraValueFiles`, with `{{ .Values.global.environment }}` in place of the environment's name. The catalog sets it to the environment being deployed. For example, Loki's entry:
```yaml
  - name: loki
    path: charts/monitoring/loki
    ...
    extraValueFiles:
      - charts/monitoring/loki/values-{{ .Values.global.environment }}.yaml
```

## Document the Overlays

List your overlays in your chart's `README.md`, under `## What's Inside`. For example, in [`charts/monitoring/loki/README.md`](../charts/monitoring/loki/README.md):
```markdown
- **[values-dev.yaml](values-dev.yaml)**, **[values-staging.yaml](values-staging.yaml)**, and **[values-prod.yaml](values-prod.yaml)**: per-environment overrides.
```

## Reuse Another Environment's Overlays

An environment loads the overlays named after its [`environment_alias`](/docs/reference/hcl_configuration/#environmenthcl), not its `environment`. `dev`, `staging`, and `prod` each load their own.

If you deploy the dev stack under another name with [`TG_ENVIRONMENT`](/docs/reference/environment_variable/#tg_environment-and-tg_environment_alias) (e.g. a second dev cluster), its alias defaults to that name. It then looks for overlays no chart has, and every app with one fails to sync. To load the overlays of `dev` instead, set `TG_ENVIRONMENT_ALIAS` in the `.env` of your catalog fork:
```bash
export TG_ENVIRONMENT_ALIAS=dev
```

Then continue at [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev). `dev` only tests your `values-dev.yaml`. Your `values-staging.yaml` and `values-prod.yaml` are first deployed when you [release the change](/docs/applications/release-an-app-change/).
