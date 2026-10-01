# `external-dns` Helm Chart Reference

The [`external-dns` chart](./) deploys [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/) via the upstream `external-dns` chart, reused for both the private and public hosted zones. Each `external-dns-*-values.yaml` file in this directory is one instance, loaded via `extraValueFiles` in [`apps/values.yaml`](../../apps/values.yaml). [Values](#values) lists only what this chart sets. For every other key, read the upstream [`values.yaml`](https://github.com/kubernetes-sigs/external-dns/blob/master/charts/external-dns/values.yaml).

For setup steps, read [How to Expose an App](https://eks-forge.readthedocs.io/latest/docs/applications/expose-an-app/).

## What's Inside

- **[templates/predelete-hook.yaml](templates/predelete-hook.yaml)**: a `PreDelete` hook that delays an instance's teardown, giving ExternalDNS time to notice a just-removed `Ingress` or `HTTPRoute` and clean up its Route53 records first
- **[templates/network-policy.yaml](templates/network-policy.yaml)**: this instance's `CiliumNetworkPolicy`. Egress to the Route53 API is scoped via `toCIDR` to `vpcEndpointCidrs.route53`, not `toEntities: world`
- **[values.yaml](values.yaml)**: see [Values](#values)
- **[values.schema.json](values.schema.json)**: rejects the values the catalog injects via `appParams` when empty, so a missing injection fails the render
- **[placeholder-values.yaml](placeholder-values.yaml)**: used only by `scripts/validate-helm.sh`, so standalone `helm template` and kubeconform pass
- **[external-dns-private-values.yaml](external-dns-private-values.yaml)**: `external-dns-private` instance, private hosted zone, claims `scope: private` resources
- **[external-dns-public-values.yaml](external-dns-public-values.yaml)**: `external-dns-public` instance, public hosted zone, claims `scope: public` resources

## Values

### Network Policy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| vpcEndpointCidrs.route53 | list | `[]` | Route53 VPC interface endpoint IPs the network policy allows egress to. Injected by the catalog via `appParams`. |

### ExternalDNS

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| external-dns.txtOwnerId | string | `""` | TXT registry owner, the EKS cluster name. Injected per instance by the catalog via `appParams`. |
| external-dns.txtPrefix | string | `""` | TXT record prefix, unique per instance. Injected per instance by the catalog via `appParams`. |
| external-dns.domainFilters | list | `[]` | Hosted zone domain this instance manages. Injected per instance by the catalog via `appParams`. |
| external-dns.sources | list | see values.yaml | Watches `Service`, `Ingress`, and `HTTPRoute` resources. |
| external-dns.policy | string | `"sync"` | `sync` also deletes the records this instance owns once their source is gone. |
| external-dns.serviceMonitor | object | `{"enabled":true}` | Enables the Prometheus `ServiceMonitor`. |
| external-dns.annotationFilter | string | `""` | Only claims resources with this `external-dns.alpha.kubernetes.io/scope` annotation. Set per instance by `*-values.yaml`. |
| external-dns.extraArgs.aws-zone-type | string | `""` | Route53 zone type, `private` or `public`. Set per instance by `*-values.yaml`. |
| external-dns.serviceAccount.name | string | `""` | Must match the catalog's Pod Identity association. Set per instance by `*-values.yaml`. |

### Scheduling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| external-dns.resources | object | see values.yaml | Resource requests and limits. |
| external-dns.nodeSelector | object | see values.yaml | Pins pods to the `elastic` NodePool, with a matching `tolerations` entry. |

## Upstream Dependencies

- **[`external_dns`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/external_dns)** (catalog): provisions the IAM role each instance's `serviceAccount.name` assumes via Pod Identity
