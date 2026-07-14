# helm-httproute

Generic `HTTPRoute` chart bound to a shared `Gateway`, reused by every app that needs a hostname. Each `*-values.yaml` file in this directory is one instance.

## What's Inside

- **[templates/httproute.yaml](templates/httproute.yaml)**: binds to both the `http` and `https` listener `sectionName`s of the target `Gateway`, so the route works over either
- **[values.yaml](values.yaml)**: empty placeholders. Each instance's `*-values.yaml` is loaded via `extraValueFiles` in [`apps/values.yaml`](../apps/values.yaml)

Every instance's `annotations` sets `external-dns.alpha.kubernetes.io/scope` to `public` or `private`. `helm-external-dns-public` and `helm-external-dns-private` each filter on that annotation to claim only the routes meant for their hosted zone.

Some instances don't set `backendRef.name` in their values file, because plain YAML can't compose a value like `"<release>-grafana"` from the Helm release name. The catalog's [`app_of_apps` unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl) injects it via `appParams` instead.

## Integration

- **[`helm-gateway-api-gateway`](../helm-gateway-api-gateway)**: `gateway.name` and `gateway.namespace` in each instance's values file must reference `gateway-public` or `gateway-private` to match the intended `scope`
- **[`helm-external-dns-public`](../helm-external-dns-public)** and **[`helm-external-dns-private`](../helm-external-dns-private)**: consume the `scope` annotation to decide which zone gets the DNS record
