# `argocd-server-grpc-service` Manifests Reference

The [`argocd-server-grpc-service` manifests](./) add a second `Service` and its target group config for ArgoCD's gRPC traffic, routed via the shared private Gateway's [`httproute`](../../charts/gateway-api/httproute).

## What's Inside

- **[service.yaml](service.yaml)**: `argocd-server-grpc`, a second `ClusterIP` `Service` fronting the same `argocd-server` pods
- **[target-group-configuration.yaml](target-group-configuration.yaml)**: sets `protocolVersion: GRPC` on that Service's ALB target group. AWS LBC matches it to the Service by `targetReference.name` and namespace

## gRPC Target Group

<!-- MIGRATE: explanation, move to the site's explanation docs -->
ArgoCD serves the web UI and gRPC (CLI, API) on the same port, but the ALB needs a separate target group per protocol version. No explicit link to the Gateway is needed.

## Why It's Defined Here

<!-- MIGRATE: explanation, move to the site's explanation docs -->
This used to live inside the catalog's Terraform-managed ArgoCD Helm release. On `terragrunt destroy`, the `app_of_apps` unit, and with it AWS Load Balancer Controller, is torn down before `argocd/helm`. With these resources still living in `argocd/helm`, their deletion happened after the controller was already gone, so nothing reconciled the target group's removal and it leaked. Moving them here means ArgoCD deletes them while the controller is still running.
