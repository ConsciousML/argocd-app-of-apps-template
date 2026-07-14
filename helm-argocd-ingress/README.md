# helm-argocd-ingress

Deploys ArgoCD server's `Ingress` (ALB) and the extra `Service` its gRPC traffic needs.

## What's Inside

- **[templates/service-grpc.yaml](templates/service-grpc.yaml)**: a second `Service` fronting the same `argocd-server` pods, with `backend-protocol-version: GRPC`. ArgoCD serves both the web UI and gRPC (CLI, API) traffic on the same port, but the ALB needs a separate target group per protocol version to route gRPC correctly
- **[templates/ingress.yaml](templates/ingress.yaml)**: routes requests with a `Content-Type: application/grpc` header to `argocd-server-grpc`, everything else to `argocd-server`

## Integration

- **[`app_of_apps`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl)** (catalog): injects `host` and `certificateArn` via `appParams`, the ARN comes from the catalog's `acm_certificate` unit under `route53`
- **[`helm-external-dns-private`](../helm-external-dns-private)**: this `Ingress` is annotated `external-dns.alpha.kubernetes.io/scope: private`, so only the private ExternalDNS instance creates its DNS record

## Why Service GRPC Is Defined Here

This `Ingress` and `Service` used to be defined inside the catalog's Terraform-managed ArgoCD Helm release. On `terragrunt destroy`, the `app_of_apps` unit, and with it the AWS Load Balancer Controller, is torn down before `argocd/helm`. With the `Ingress` still living in `argocd/helm`, its deletion happened after the controller that owns the ALB was already gone, so nothing reconciled the ALB's removal and it leaked. Moving both resources here means ArgoCD deletes them while the controller is still running to clean up the ALB.
