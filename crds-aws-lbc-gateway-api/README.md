# crds-aws-lbc-gateway-api

Installs the AWS Load Balancer Controller's Gateway API CRDs (`LoadBalancerConfiguration`, `TargetGroupConfiguration`, `ListenerRuleConfiguration`) from the [aws-load-balancer-controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller) repository.

## What's Inside

- **[application.yaml](application.yaml)**: a nested ArgoCD `Application` sourcing manifests directly from the upstream repo instead of a local chart. `targetRevision` must track `helm-aws-lbc`'s chart version. `prune: false` so a sync never deletes them. `helm-aws-lbc`'s chart already bundles these same CRDs. They're installed again here as a wave `-1` prerequisite so `gateway-class` can depend on them directly instead of on the controller being healthy

## Integration

- **[`helm-aws-lbc`](../helm-aws-lbc)**: the controller that implements these CRDs
