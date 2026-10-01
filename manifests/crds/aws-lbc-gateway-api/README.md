<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/manifests/crds/aws-lbc-gateway-api/. It is not meant to be read directly in this repository. -->

# `crds-aws-lbc-gateway-api` Manifests Reference

The [`crds-aws-lbc-gateway-api` manifests](./) install the AWS Load Balancer Controller's Gateway API CRDs (`LoadBalancerConfiguration`, `TargetGroupConfiguration`, `ListenerRuleConfiguration`) from the [aws-load-balancer-controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller) repository.

## What's Inside

- **[application.yaml](application.yaml)**: a nested ArgoCD `Application` sourcing manifests directly from the upstream repo instead of a local chart. `targetRevision` must track [`aws-lbc`](../../../charts/aws-lbc)'s chart version. `prune: false`, so a sync never deletes them

## Separate CRD Install

<!-- MIGRATE: explanation, move to the site's explanation docs -->
`aws-lbc`'s chart already bundles these same CRDs. They're installed again here as a wave `-1` prerequisite so `gateway-class` can depend on them directly instead of on the controller being healthy.
