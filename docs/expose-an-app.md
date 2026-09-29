{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Expose an App

This guide shows you how to route an app through the public or private [gateway](https://gateway-api.sigs.k8s.io/reference/api-types/gateway/), and give it a hostname. You need it when your app serves HTTP to users or to your team (e.g. a web UI or an API). It's one of the [Extra Steps](/docs/applications/add-edit-or-remove-an-app/#extra-steps) of adding or editing an app, and assumes you've created a branch in both forks, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch).

Pick the gateway that fits your app. Each one is an [Application Load Balancer](https://aws.amazon.com/elasticloadbalancing/application-load-balancer/) (ALB), and the tabs below follow this choice:
- **Public**: reachable from the internet, at `<subdomain>.public.<env>.<base_domain>` (e.g. podinfo, at `podinfo.public.dev.example.com`).
- **Private**: reachable only from inside the VPC or over [Tailscale](/docs/security/tailscale/), at `<subdomain>.private.<env>.<base_domain>` (e.g. Goldilocks, at `goldilocks.private.dev.example.com`).

## In Your App of Apps Fork

### Add a Route Values File

The [`httproute`](../charts/gateway-api/httproute/) chart creates an [`HTTPRoute`](https://gateway-api.sigs.k8s.io/reference/api-types/httproute/), which binds a hostname on a gateway to your app's [`Service`](https://kubernetes.io/docs/concepts/services-networking/service/). Next to its `values.yaml`, add a `<app>-httproute-values.yaml` that sets:
- `name`: the name of the `HTTPRoute`.
- `rules`: one entry per path to route, with its `matches` and the `backendRefKey` it sends traffic to.
- `backendRefs`: the `Service` behind each `backendRefKey`, with its `name` and `port` (the `Service` port, not the container's).
- `annotations`: `external-dns.alpha.kubernetes.io/scope`, set to `public` or `private` to match your gateway. [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/) only creates a DNS record for a route with the matching scope.

Don't set `host`. The catalog injects it (see [Inject the Hostname](#inject-the-hostname)).

<Tabs groupId="gateway">
<TabItem value="public" label="Public">

For example, [`podinfo-httproute-values.yaml`](../charts/gateway-api/httproute/podinfo-httproute-values.yaml):
```yaml
name: podinfo
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    backendRefKey: default
backendRefs:
  default:
    name: podinfo
    port: 9898
annotations:
  external-dns.alpha.kubernetes.io/scope: public
```

</TabItem>
<TabItem value="private" label="Private">

For example, [`goldilocks-httproute-values.yaml`](../charts/gateway-api/httproute/goldilocks-httproute-values.yaml):
```yaml
name: goldilocks
rules:
  - matches:
      - path:
          type: PathPrefix
          value: /
    backendRefKey: default
backendRefs:
  default:
    name: goldilocks-dashboard
    port: 80
annotations:
  external-dns.alpha.kubernetes.io/scope: private
```

</TabItem>
</Tabs>

### Declare the Route Entry

Add an `<app>-httproute` entry under `applications` in [`apps/values.yaml`](../apps/values.yaml), with:
- `path`: the `httproute` chart.
- `destination.namespace`: your app's namespace. The `HTTPRoute` can only reach a `Service` in its own namespace.
- `syncWave`: after both your gateway, at wave `6`, and your app (see [Set the Sync Wave](/docs/applications/add-edit-or-remove-an-app/#set-the-sync-wave)).
- `extraValueFiles`: the existing values file of your gateway, [`public-gateway-values.yaml`](../charts/gateway-api/gateway/public-gateway-values.yaml) or [`private-gateway-values.yaml`](../charts/gateway-api/gateway/private-gateway-values.yaml), which names the gateway your route attaches to. Then your [route values file](#add-a-route-values-file).

<Tabs groupId="gateway">
<TabItem value="public" label="Public">

For example, podinfo's route runs after `gateway-public` (wave `6`), at wave `7`:
```yaml
  # Depends on:
  # - gateway-public
  # - podinfo (the backend Service)
  - name: podinfo-httproute
    path: charts/gateway-api/httproute
    destination:
      namespace: podinfo
    syncWave: 7
    extraValueFiles:
      - charts/gateway-api/gateway/public-gateway-values.yaml
      - charts/gateway-api/httproute/podinfo-httproute-values.yaml
```

</TabItem>
<TabItem value="private" label="Private">

For example, Goldilocks' route runs after `goldilocks` (wave `8`), at wave `9`:
```yaml
  # Depends on:
  # - gateway-private
  # - goldilocks (the backend Service)
  - name: goldilocks-httproute
    path: charts/gateway-api/httproute
    destination:
      namespace: goldilocks
    syncWave: 9
    extraValueFiles:
      - charts/gateway-api/gateway/private-gateway-values.yaml
      - charts/gateway-api/httproute/goldilocks-httproute-values.yaml
```

</TabItem>
</Tabs>

### Allow the Key in the Apps Chart

The catalog injects `host` through [`appParams`](/docs/applications/how-the-app-of-apps-works/#appparams-injection). Allow your `<app>-httproute` key in the apps chart, by following [Allow the Key in the Apps Chart](/docs/applications/pass-terraform-values-to-an-app/#allow-the-key-in-the-apps-chart). For example, podinfo's key in [`apps/values.schema.json`](../apps/values.schema.json):
```json
"appParams": {
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "podinfo-httproute": { "type": "object" },
    ...
  }
}
```

Then add its placeholder, by following [Add Placeholders to the Apps Chart](/docs/applications/pass-terraform-values-to-an-app/#add-placeholders-to-the-apps-chart). For example, podinfo's placeholder in [`apps/placeholder-values.yaml`](../apps/placeholder-values.yaml):
```yaml
appParams:
  podinfo-httproute:
    host: "placeholder.example.com"
  ...
```

### Allow Gateway Traffic

If your app already has a `CiliumNetworkPolicy`, allow the gateway's traffic in it. Otherwise, do it when you [Restrict the App's Traffic](/docs/applications/add-edit-or-remove-an-app/#restrict-the-apps-traffic).

The ALB isn't a pod, so Cilium sees its traffic as coming from `world`. Allow ingress from `world` on the container port, not the `Service` port. For example, in [`manifests/podinfo/podinfo-network-policy.yaml`](../manifests/podinfo/podinfo-network-policy.yaml):
```yaml
spec:
  endpointSelector:
    matchLabels:
      app: podinfo
  ingress:
    - fromEntities:
        - world
      toPorts:
        - ports:
            - port: "9898"
              protocol: TCP
    ...
```

For the rest of the policy, see [Control an App's Network Traffic](/docs/security/control-an-app-network-traffic/).

## In Your Catalog Fork

### Add the Hostname

In [`pipelines/dns.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/pipelines/dns.hcl), add your app's subdomain. Keep it a single label (no dot), since the wildcard certificate only covers one level. For example:
```hcl
locals {
  ...
  subdomain_podinfo    = "podinfo"
  subdomain_goldilocks = "goldilocks"
}
```

Then, in [`pipelines/dev/eks/domains.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/pipelines/dev/eks/domains.hcl), build the full hostname under your gateway's domain, `domain_env_public` or `domain_env_private`:
```hcl
locals {
  ...
  domain_public_podinfo     = "${local.dns.subdomain_podinfo}.${local.domain_env_public}"
  domain_private_goldilocks = "${local.dns.subdomain_goldilocks}.${local.domain_env_private}"
}
```

See the [HCL Configuration](/docs/reference/hcl_configuration/#domainshcl) reference for what each file sets.

### Inject the Hostname

In the `argocd_app_of_apps` unit, [`units/eks/addons/argocd/app_of_apps/terragrunt.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl), read your hostname from `domains.hcl` in `locals`:
```hcl
locals {
  domains_hcl               = find_in_parent_folders("domains.hcl")
  domain_public_podinfo     = read_terragrunt_config(local.domains_hcl).locals.domain_public_podinfo
  domain_private_goldilocks = read_terragrunt_config(local.domains_hcl).locals.domain_private_goldilocks
  ...
}
```

Then, under `inputs.helm_values.appParams`, set it as the `host` of your `<app>-httproute` key (see [Add the `appParams` Entry](/docs/applications/pass-terraform-values-to-an-app/#add-the-appparams-entry)):
```hcl
appParams = {
  ...
  "podinfo-httproute" = {
    host = local.domain_public_podinfo
  }
  "goldilocks-httproute" = {
    host = local.domain_private_goldilocks
  }
}
```

### Probe the Hostname

The [blackbox exporter](https://github.com/prometheus/blackbox_exporter) calls each of its target URLs from inside the cluster, like a user would, and Prometheus alerts when one stops answering with a `2xx`. To get alerted when your app is unreachable, add its URL to the targets, under the `blackbox-exporter` key of `appParams`. For example:
```hcl
"blackbox-exporter" = {
  "prometheus-blackbox-exporter" = {
    serviceMonitor = {
      targets = [
        ...
        { name = "podinfo", url = "https://${local.domain_public_podinfo}" },
        { name = "goldilocks", url = "https://${local.domain_private_goldilocks}" },
      ]
    }
  }
}
```

{/* TODO: document testing a new hostname in staging. The live repository's staging tests
(tests/staging_stack_test.go) poll each entry of endpointChecks, reading its host from a
domain_name_<app> unit output. To cover a new app: copy a units/eks/domain_name/<app> unit in
the catalog, add its block to the dev stack, and add an endpointChecks entry in live. */}

Then follow [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev). After you sync, also check that your hostname answers, replacing `<host>`. For a private hostname, connect to [Tailscale](/docs/security/tailscale/) first, by running `tailscale up`. ExternalDNS can take a minute to create the record:
```bash
curl -I https://<host>
```

To ship your change to `staging` and `prod`, see [Release an App Change](/docs/applications/release-an-app-change/). Before you release, port your `dns.hcl` and `domains.hcl` lines to your live fork, as in [Update the Shared Configuration](/docs/iac/bump-the-catalog-version/#update-the-shared-configuration).
