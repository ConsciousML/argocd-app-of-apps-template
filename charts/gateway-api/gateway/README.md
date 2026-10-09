<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/helm_charts/gateway-api/gateway/. It is not meant to be read directly in this repository. -->

# `gateway` Helm Chart Reference

The [`gateway` chart](./) renders a Gateway API `Gateway` backed by an ALB, in two instances: `gateway-public` (internet-facing) and `gateway-private` (internal). Each `*-gateway-values.yaml` file in this directory is one instance, loaded via `extraValueFiles` in [`apps/values.yaml`](../../../apps/values.yaml).

For setup steps, read [How to Expose an App](/docs/applications/expose-an-app/).

## What's Inside

- **[templates/gateway.yaml](templates/gateway.yaml)**: the `Gateway`, with an `http` (80) and an `https` (443) listener accepting routes from all namespaces
- **[templates/load-balancer-configuration.yaml](templates/load-balancer-configuration.yaml)**: `certificateArn` becomes the default certificate for the `HTTPS:443` listener
- **[templates/target-group-configuration.yaml](templates/target-group-configuration.yaml)**: `targetType: ip`, so the ALB targets pod IPs directly instead of node ports
- **[values.yaml](values.yaml)**: empty defaults, see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects the values the catalog injects via `appParams` when empty, so a missing injection fails the render
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass
- **[public-gateway-values.yaml](public-gateway-values.yaml)**: `gateway-public` instance. Also loaded by every public [`httproute`](../httproute) instance to target this `Gateway`
- **[private-gateway-values.yaml](private-gateway-values.yaml)**: `gateway-private` instance. Also loaded by every private [`httproute`](../httproute) instance to target this `Gateway`

## Values

### Gateway

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| gateway.name | string | `""` | `Gateway` name. Set per instance by `public-gateway-values.yaml` or `private-gateway-values.yaml`. |
| gateway.namespace | string | `""` | `Gateway` namespace, shared by its `LoadBalancerConfiguration` and `TargetGroupConfiguration`. |
| gatewayClassName | string | `""` | `GatewayClass` name. Set by the [`gateway-class`](../gateway-class) chart's `values.yaml`, loaded via `extraValueFiles`. |

### Load Balancer

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| scheme | string | `""` | ALB scheme, `internet-facing` (public) or `internal` (private). |
| targetGroupConfigName | string | `""` | `TargetGroupConfiguration` name. |
| loadBalancerConfigName | string | `""` | `LoadBalancerConfiguration` name. |
| certificateArn | string | `""` | ACM certificate ARN, the default certificate of the `HTTPS:443` listener. Injected by the catalog via `appParams`. |

## Sync Waves

Each template sets its own `argocd.argoproj.io/sync-wave`, ordering the three resources within one Application. The `syncWave` on the `gateway-public` and `gateway-private` entries in `apps/values.yaml` is separate. It orders this Application against the others.

## Upstream Dependencies

- **[`route53`](https://github.com/ConsciousML/eks-forge-catalog/tree/main/units/eks/route53)** (catalog): its `acm_certificate` unit issues the wildcard certificate injected into `certificateArn`
- **[`gateway-class`](../gateway-class)**: both instances load its `values.yaml` via `extraValueFiles` to reference the same `gatewayClassName`
