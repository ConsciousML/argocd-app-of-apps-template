# helm-gateway-api-gateway

Deploys a Gateway API `Gateway` backed by an ALB, in two instances: `gateway-public` (internet-facing) and `gateway-private` (internal).

## What's Inside

- **[templates/target-group-configuration.yaml](templates/target-group-configuration.yaml)**: `targetType: ip` so the ALB targets pod IPs directly instead of node ports
- **[templates/load-balancer-configuration.yaml](templates/load-balancer-configuration.yaml)**: `certificateArn` becomes the default certificate for the `HTTPS:443` listener
- **[public-gateway-values.yaml](public-gateway-values.yaml)** and **[private-gateway-values.yaml](private-gateway-values.yaml)**: set each instance's `gateway.name`, `scheme`, and config names. Loaded via `extraValueFiles` on the `gateway-public` and `gateway-private` entries in [`apps/values.yaml`](../apps/values.yaml). `values.yaml` itself only holds empty placeholders

Each template carries its own `argocd.argoproj.io/sync-wave` annotation, ordering the three resources within this single Application. That's separate from the top-level `syncWave` these two app entries carry in `apps/values.yaml`, which orders this Application against every other one.

## Upstream Dependencies

- **[`route53`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/route53)** (catalog): its `acm_certificate` unit issues the wildcard certificate. The catalog's [`app_of_apps` unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl) injects its ARN into both instances' `certificateArn`
- **[`helm-gateway-api-gateway-class`](../helm-gateway-api-gateway-class)**: both instances load its `values.yaml` via `extraValueFiles` to reference the same `gatewayClassName`
