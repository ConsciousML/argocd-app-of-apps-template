# helm-external-dns-private

Deploys [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/) scoped to the private hosted zone, watching `Service`, `Ingress`, and `HTTPRoute` resources tagged `external-dns.alpha.kubernetes.io/scope=private`.

## What's Inside

- **[values.yaml](values.yaml)**: `txtOwnerId`, `txtPrefix`, and `domainFilters` are placeholders, overridden at sync time by the catalog's [`app_of_apps` unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl) via `appParams`. `registry: txt` tracks record ownership with a TXT entry per record, so `policy: sync` only deletes records this instance actually created
- **[templates/predelete-hook.yaml](templates/predelete-hook.yaml)**: a `PreDelete` hook that delays this app's teardown, giving ExternalDNS time to notice a just-removed `Ingress` or `HTTPRoute` and clean up its Route53 records first

## Integration

- **[`external_dns`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/external_dns)** (catalog): provisions the IAM role this instance's `external-dns-private` service account assumes via Pod Identity, scoped to the private hosted zone
- **[`helm-httproute`](../helm-httproute)**: this instance only picks up `HTTPRoute`s annotated `scope: private`
