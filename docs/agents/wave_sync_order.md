# Assigning sync waves

`apps/values.yaml`'s `syncWave` field controls the order ArgoCD creates/syncs child
`Application` resources in. Waves are not chosen by feel — derive them mechanically from
the dependency graph.

## 1. Classify each entry

- **Prerequisite**: renders no `Deployment`/`StatefulSet`/`DaemonSet`/`Service` (CRDs,
  `StorageClass`, `GatewayClass`, `Gateway`/`LoadBalancerConfiguration`/
  `TargetGroupConfiguration`, `SecretStore`/`ExternalSecret`, `HTTPRoute`, ...).
- **App**: renders an actual workload (has a `Deployment`/`StatefulSet`/`DaemonSet` and/or
  `Service`), e.g. a controller, `kube-prometheus-stack`, `podinfo`.

## 2. Write down what each entry actually depends on

For every entry, list the *other app-of-apps entries* it needs to already exist/be healthy
— not the wave number. In the file, replace any "why this wave" comment with a plain
dependency list:

```yaml
# Depends on:
# - gateway-class
# - aws-lbc (controller reconciles into an ALB)
- name: gateway-public
  ...
```

No comment at all if there are no dependencies. Use `Same dependencies as X.` for entries
that are functionally duplicates of another (e.g. `gateway-private` vs `gateway-public`,
the three Prometheus stack HTTPRoutes).

A "dependency" here means: the other entry's resource must exist and be reported `Healthy`
by ArgoCD before this one can be created or would function correctly. Health-check
semantics count — e.g. `GatewayClass` only reports `Healthy` once the AWS LBC controller
sets its `Accepted` condition, so `gateway-class` genuinely depends on `aws-lbc` even
though nothing in `gateway-class`'s own manifest references it.

## 3. Compute the wave number from the dependency graph

Not a judgment call — compute it:

- No dependencies, prerequisite → `-1`
- No dependencies, app → `0`
- Otherwise → `max(syncWave of every dependency) + 1`

A prerequisite is not required to stay negative — if its real dependency is an app, its
wave follows the formula like anything else (e.g. `gateway-class` depends on
`aws-lbc` at wave 0, so it lands at wave 1, not `-1`).

Recompute the whole graph whenever a dependency changes, rather than patching one number
in isolation — a shifted upstream wave cascades to everything downstream of it.

## 4. Remember deletion is reversed

ArgoCD prunes highest wave first on delete. Two consequences to check for every new entry:

- If an app's controller might need to still be running to clean up its own custom
  resources (e.g. AWS LBC needs to be alive to tear down an ALB when its `Gateway` is
  deleted), the custom resource must be a **strictly higher** wave than the controller —
  never the same wave, or deletion order between them is unspecified and the controller
  could disappear first, leaving the resource's finalizer stuck forever.
- Never put a prerequisite in the *same* wave as the app it depends on for this reason,
  even when they'd otherwise compute to the same number.
