# argocd-server-grpc-service

Plain manifests (no Helm) for the extra `Service` ArgoCD's gRPC traffic needs, routed via the shared private Gateway's `HTTPRoute` (see [`helm-httproute`](../helm-httproute)).

## What's Inside

- **[service.yaml](service.yaml)**: a second `Service` fronting the same `argocd-server` pods. ArgoCD serves the web UI and gRPC (CLI, API) on the same port, but the ALB needs a separate target group per protocol version
- **[target-group-configuration.yaml](target-group-configuration.yaml)**: sets `protocolVersion: GRPC` on that target group. AWS LBC resolves it automatically by matching its `targetReference.name` and namespace to the Service, no explicit link to the Gateway needed

## Why It's Defined Here

This used to live inside the catalog's Terraform-managed ArgoCD Helm release. On `terragrunt destroy`, the `app_of_apps` unit, and with it AWS Load Balancer Controller, is torn down before `argocd/helm`. With these resources still living in `argocd/helm`, their deletion happened after the controller was already gone, so nothing reconciled the target group's removal and it leaked. Moving them here means ArgoCD deletes them while the controller is still running.
