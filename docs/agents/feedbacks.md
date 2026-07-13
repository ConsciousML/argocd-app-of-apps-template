# Feedback

Lessons from past work in this repo (and its paired catalog repo) that aren't obvious from
reading the code alone.

- **appParams boundary**: the catalog's `app_of_apps` unit should only inject `appParams`
  values that come from a `dependency` block or genuinely belong to infrastructure (ARNs,
  hostnames, IAM role names, Secrets Manager secret names). Static or Kubernetes-behavior
  config (annotations, `refreshPolicy`, `targetCreationPolicy`, etc.) belongs as a default
  in the app-of-apps chart itself, not threaded through Terragrunt.
- **Defer destructive cleanup during migrations**: when migrating a Terraform-managed
  resource to ArgoCD, leave the old Terraform units and modules in place (just unreferenced in
  the stack file) until the new app-of-apps deployment is confirmed working. Don't delete
  proactively in the same pass.
- **Prefer generic, reused charts**: when multiple entries need near-identical manifests
  (e.g. three HTTPRoutes, three SecretStore and ExternalSecret pairs), write one generic
  values-driven chart and reuse it via multiple `apps/values.yaml` entries, the same pattern
  `helm-eso-secret-sync` uses. Don't write bespoke per-consumer charts or templates.
- **`fullnameOverride` doesn't propagate to subcharts**: it only pins an umbrella chart's
  own templates. Bundled subcharts (e.g. `kube-prometheus-stack`'s `grafana`,
  `kube-state-metrics`, `node-exporter`) derive their resource names from the Helm
  **release name** independently. Any cross-app reference (e.g. an `HTTPRoute`
  `backendRef`) that assumes a subchart's Service name must set `tool.helm.releaseName`
  explicitly to match, or it'll silently point at the wrong name.

