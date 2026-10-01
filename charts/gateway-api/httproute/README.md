# `httproute` Chart Reference

The [`httproute` chart](./) renders a generic `HTTPRoute` bound to a shared `Gateway`, reused by every app that needs a hostname. Each `*-values.yaml` file in this directory is one instance, loaded via `extraValueFiles` in [`apps/values.yaml`](../../../apps/values.yaml).

For setup steps, read [How to Expose an App](https://eks-forge.readthedocs.io/latest/docs/applications/expose-an-app/).

## What's Inside

- **[templates/httproute.yaml](templates/httproute.yaml)**: binds to both the `http` and `https` listeners of the target `Gateway`

## Values

### Gateway

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| gateway.name | string | `""` | Target `Gateway` name. Set by the shared `*-gateway-values.yaml` in `extraValueFiles`. |
| gateway.namespace | string | `""` | Target `Gateway` namespace. Set by the shared `*-gateway-values.yaml` in `extraValueFiles`. |

### Route

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| name | string | `""` | `HTTPRoute` name. |
| host | string | `""` | Hostname. Injected by the catalog via `appParams` (from `domains.hcl`), never set per instance. |
| rules | list | `[]` | Route rules. `matches` is Gateway API `HTTPRouteMatch` syntax. `backendRefKey` is a key into `backendRefs`. |
| backendRefs | object | `{}` | Backends by key, each with `name` and `port`. |
| annotations | object | `{}` | Must set `external-dns.alpha.kubernetes.io/scope` to `public` or `private`, else no DNS record. |

## Upstream Dependencies

- **[`gateway`](../gateway)**: `gateway.name` and `gateway.namespace` in each instance's values file must reference `gateway-public` or `gateway-private` to match the intended `scope`
