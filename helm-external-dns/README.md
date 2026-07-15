# helm-external-dns

Generic [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/) chart, reused for both the private and public hosted zones. Each `*-values.yaml` file in this directory is one instance.

## What's Inside

- **[values.yaml](values.yaml)**: placeholders, see inline comments for what overrides each and when
- **[external-dns-private-values.yaml](external-dns-private-values.yaml)** and **[external-dns-public-values.yaml](external-dns-public-values.yaml)**: per-instance overrides, loaded via `extraValueFiles` in [`apps/values.yaml`](../apps/values.yaml)
- **[templates/predelete-hook.yaml](templates/predelete-hook.yaml)**: a `PreDelete` hook that delays an instance's teardown, giving ExternalDNS time to notice a just-removed `Ingress` or `HTTPRoute` and clean up its Route53 records first

## Upstream Dependencies

- **[`external_dns`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/external_dns)** (catalog): provisions the IAM role each instance's `serviceAccount.name` assumes via Pod Identity
