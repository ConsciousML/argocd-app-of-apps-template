# httproute

Generic `HTTPRoute` chart bound to a shared `Gateway`, reused by every app that needs a hostname. Each `*-values.yaml` file in this directory is one instance.

## What's Inside

- **[templates/httproute.yaml](templates/httproute.yaml)**: binds to both the `http` and `https` listener `sectionName`s of the target `Gateway`, so the route works over either
- **[values.yaml](values.yaml)**: empty placeholders. Each instance's `*-values.yaml` is loaded via `extraValueFiles` in [`apps/values.yaml`](../../../apps/values.yaml). See its inline comments for the `rules` and `backendRefs` shape and which fields the catalog's `app_of_apps` unit injects via `appParams` instead

Every instance's `annotations` sets `external-dns.alpha.kubernetes.io/scope` to `public` or `private`. Each `external-dns` instance filters on that annotation to claim only the routes meant for its hosted zone.

## Upstream Dependencies

- **[`gateway`](../gateway)**: `gateway.name` and `gateway.namespace` in each instance's values file must reference `gateway-public` or `gateway-private` to match the intended `scope`
