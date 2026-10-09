{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Write Network Policies

This guide shows you how to deny all of an app's network traffic, then allow only what it needs, with [Cilium network policies](https://docs.cilium.io/en/stable/security/policy/). You need it when you add an app, or when traffic to or from an app is dropped. It assumes you've created a branch in your app of apps fork, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch). If your app calls an AWS API, create a branch in your catalog fork too.

If you're new to Cilium network policies, read [How Network Policies Work](/docs/security/how-network-policies-work/) first.

## Deny All Ingress and Egress in Your Namespace

If your namespace is already in [`default-deny.yaml`](../manifests/network-policies/cluster-wide/default-deny.yaml), skip to [Find Dropped Traffic](#find-dropped-traffic).

Otherwise, add it to the `values` list. For example, podinfo's namespace:
```yaml
spec:
  endpointSelector:
    matchExpressions:
      - key: io.kubernetes.pod.namespace
        operator: In
        values:
          ...
          - podinfo
          ...
```

## Deploy the App

Deploy your app to `dev`, along with its namespace in `default-deny.yaml`, by following [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev), up to the sync.

## Find Dropped Traffic

If your app was already running, restart its pods first, so Hubble also sees the traffic they only send on startup.

From the root of your catalog fork, list the traffic dropped in the cluster with [Hubble](https://docs.cilium.io/en/stable/observability/hubble/):
```bash
hubble observe --verdict DROPPED -P | grep -v "Unsupported L3"
```

To only show the flows to or from your app's namespace, add `-n <namespace>`. For other filters, see Cilium's [Hubble CLI guide](https://docs.cilium.io/en/stable/observability/hubble/hubble-cli/).

Each line is one dropped flow, from a source on the left to a destination on the right, with its port. For example, for an app `my-app`:
```text
Oct  2 10:15:03.412: my-app/my-app-7d9f8c6b5-x2kqz:43512 (ID:21034) <> kube-system/coredns-5d78c9869d-4kq7p:53 (ID:8410) policy-verdict:none EGRESS DENIED (UDP)
Oct  2 10:15:07.208: monitoring/prometheus-kube-prometheus-stack-prometheus-0:51234 (ID:30122) <> my-app/my-app-7d9f8c6b5-x2kqz:8080 (ID:21034) policy-verdict:none INGRESS DENIED (TCP Flags: SYN)
```

`EGRESS DENIED` means the source's policies lack the rule (here, `my-app` resolving DNS). `INGRESS DENIED` means the destination's policies lack it (here, Prometheus scraping `my-app`).

:::warning
If a drop shows `world` where you expect a pod, that pod may have started before Cilium's agent on its node, so Cilium doesn't manage it. Restart it, or run [`scripts/restart-missing-cilium-endpoints.sh`](https://github.com/ConsciousML/eks-forge-catalog/blob/main/scripts/restart-missing-cilium-endpoints.sh) from the root of your catalog fork, then look for drops again. The script restarts every workload with a pod Cilium doesn't manage, across the cluster, not only the peer. Outside `dev`, run it during a maintenance window.
:::

## Allow Each Dropped Flow

### Find Which Rule Your Peer Needs

Each dropped flow is between your app and a peer (e.g. CoreDNS, or Prometheus scraping your app):
- Your app always needs a rule that points at the peer.
- If the peer is a pod, it may also need a rule that points back at your app.

Find the peer in the table below. Its row gives:
- **Rules on**: whose policies need a rule.
- **Egress, in the source**: the rule for the end that sends the traffic.
- **Ingress, in the destination**: the rule for the end that receives it.

If your app sends the traffic, it's the source. If it receives it, it's the destination. Each rule also restricts the port with `toPorts`.

For **Both pods**, write both rules at once. Otherwise, Hubble only shows the second drop after you fix the first.

| Peer | Rules on | Egress, in the source | Ingress, in the destination | Example |
|------|----------|-----------------------|-----------------------------|---------|
| CoreDNS, resolving DNS | Your namespace, cluster-wide | Your namespace in `values` | N/A, CoreDNS allows the whole cluster | [`kube-dns-egress.yaml`](../manifests/network-policies/cluster-wide/kube-dns-egress.yaml) |
| The Kubernetes API | Your namespace, cluster-wide | Your namespace in `values` | N/A | [`kube-apiserver-egress.yaml`](../manifests/network-policies/cluster-wide/kube-apiserver-egress.yaml) |
| The EKS Pod Identity agent | Your namespace, cluster-wide | Your namespace in `values` | N/A | [`eks-pod-identity-egress.yaml`](../manifests/network-policies/cluster-wide/eks-pod-identity-egress.yaml) |
| A pod in the same namespace | Both pods | [`toEndpoints`](https://docs.cilium.io/en/stable/security/policy/layer3/#endpoints-based) on its labels | `fromEndpoints` on its labels | [`k6-loadtest-network-policy.yaml`](../manifests/podinfo/k6-loadtest-network-policy.yaml) |
| A pod in another namespace | Both pods | Same, plus `io.kubernetes.pod.namespace` | Same, plus `io.kubernetes.pod.namespace` | [`network-policy-results-cache.yaml`](../charts/monitoring/loki/templates/network-policy-results-cache.yaml) |
| The kubelet, probing your pod | Your pod | N/A | [`fromEntities: [host]`](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) | [`podinfo-network-policy.yaml`](../manifests/podinfo/podinfo-network-policy.yaml) |
| A load balancer, forwarding to your pod | Your pod | N/A | [`fromEntities: [world]`](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) | [`podinfo-network-policy.yaml`](../manifests/podinfo/podinfo-network-policy.yaml) |
| An AWS API with a VPC endpoint | Your pod | [`toCIDR`](https://docs.cilium.io/en/stable/security/policy/layer3/#cidr-based) on `vpcEndpointCidrs`, see [Allow an AWS API](#allow-an-aws-api) | N/A | [`charts/external-dns/templates/network-policy.yaml`](../charts/external-dns/templates/network-policy.yaml) |
| S3, or anything outside AWS | Your pod | [`toEntities: [world]`](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) | N/A | [`network-policy-single-binary.yaml`](../charts/monitoring/loki/templates/network-policy-single-binary.yaml) |

These are the selectors EKS Forge uses today, not every one Cilium offers. For a peer they don't fit, see Cilium's [Layer 3](https://docs.cilium.io/en/stable/security/policy/layer3/) and [Layer 4](https://docs.cilium.io/en/stable/security/policy/layer4/) policy docs.

:::warning
Only [Layer 3](https://docs.cilium.io/en/stable/security/policy/layer3/) and [Layer 4](https://docs.cilium.io/en/stable/security/policy/layer4/) rules work. Cilium doesn't support [Layer 7](https://docs.cilium.io/en/stable/security/policy/layer7/) rules (e.g. HTTP paths) when chained to the AWS VPC CNI, as in EKS Forge (see Cilium's [AWS VPC CNI chaining](https://docs.cilium.io/en/stable/installation/cni-chaining-aws-cni/) limitations). [`toFQDNs`](https://docs.cilium.io/en/stable/security/policy/layer3/#dns-based) doesn't work either, since it needs a Layer 7 DNS rule.
:::

### Write the Rule

Pick the tab that matches the **Rules on** column:
- **Cluster-wide**: for **Your namespace, cluster-wide**, a concern several namespaces share (e.g. resolving DNS).
- **Pod**: for **Your pod** or **Both pods**, a concern specific to one pod (e.g. Prometheus scraping your app).

<Tabs groupId="policy-scope">
<TabItem value="namespaces" label="Cluster-wide">

Add your namespace to the `values` list of the file in [`manifests/network-policies/cluster-wide/`](../manifests/network-policies/cluster-wide/) that allows the flow, as in [Deny All Ingress and Egress in Your Namespace](#deny-all-ingress-and-egress-in-your-namespace). For example, if your app resolves DNS names, like podinfo, add its namespace to [`kube-dns-egress.yaml`](../manifests/network-policies/cluster-wide/kube-dns-egress.yaml):
```yaml
spec:
  endpointSelector:
    matchExpressions:
      - key: io.kubernetes.pod.namespace
        operator: In
        values:
          ...
          - podinfo
```

If several namespaces need the same rule and no file allows it, add a new `CiliumClusterwideNetworkPolicy` there, one per concern, selecting namespaces the same way (see Cilium's [CiliumClusterwideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy)). For example, [`kube-apiserver-egress.yaml`](../manifests/network-policies/cluster-wide/kube-apiserver-egress.yaml):
```yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: kube-apiserver-egress
spec:
  endpointSelector:
    matchExpressions:
      - key: io.kubernetes.pod.namespace
        operator: In
        values:
          - vpa
          - goldilocks
          ...
  egress:
    - toEntities:
        - kube-apiserver
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
```

</TabItem>
<TabItem value="pod" label="Pod">

Write your app's rule in its own policy. For **Both pods**, also write the peer's rule in the peer's policy.

#### In Your App's Policy

Add one `CiliumNetworkPolicy` (see Cilium's [CiliumNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumnetworkpolicy)) per pod your app runs (one per `Deployment`, `StatefulSet`, `DaemonSet`, or `Job`), next to your app's files:
- **Plain manifests**: `manifests/<name>/<pod>-network-policy.yaml` (e.g. [`podinfo-network-policy.yaml`](../manifests/podinfo/podinfo-network-policy.yaml) and [`k6-loadtest-network-policy.yaml`](../manifests/podinfo/k6-loadtest-network-policy.yaml) in [`manifests/podinfo/`](../manifests/podinfo/)).
- **A Helm chart**: `templates/network-policy-<pod>.yaml` (e.g. [`charts/monitoring/loki/templates/`](../charts/monitoring/loki/templates/)), or `templates/network-policy.yaml` if it runs a single pod.

In each policy:
- Select the pod by its labels in `endpointSelector` (see Cilium's [Rule Basics](https://docs.cilium.io/en/stable/security/policy/intro/#rule-basics)). If the pods of your chart share their `app.kubernetes.io/name`, add their `app.kubernetes.io/component`, so each policy selects only its own pod.
- Under `ingress`, allow each source the pod receives traffic from, on its port.
- Under `egress`, allow each destination the pod sends traffic to, on its port.

For example, Loki's results cache only receives traffic, from Loki and from Prometheus, in [`charts/monitoring/loki/templates/network-policy-results-cache.yaml`](../charts/monitoring/loki/templates/network-policy-results-cache.yaml):
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: loki-results-cache
  namespace: {{ .Release.Namespace }}
spec:
  endpointSelector:
    matchLabels:
      app.kubernetes.io/name: loki
      app.kubernetes.io/component: memcached-results-cache
  ingress:
    # Read/write from the single-binary replicas.
    - fromEndpoints:
        - matchLabels:
            app.kubernetes.io/name: loki
            app.kubernetes.io/component: single-binary
      toPorts:
        - ports:
            - port: "11211"
              protocol: TCP
    # kube-prometheus-stack scraping the memcached exporter's /metrics (ServiceMonitor).
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: monitoring
            app.kubernetes.io/name: prometheus
      toPorts:
        - ports:
            - port: "9150"
              protocol: TCP
```

#### In the Peer's Policy

For **Both pods**, add the peer's rule, pointing back at your app, to the peer's existing policy. To find it, list the policies in the peer's namespace, and pick the one named after the peer (e.g. `prometheus` for `prometheus-kube-prometheus-stack-prometheus-0`):
```bash
kubectl get ciliumnetworkpolicies -n <peer-namespace>
```

Then, from the root of your app of apps fork, find its file:
```bash
grep -rln "name: <policy>" charts manifests
```

If no file matches, the policy is named after its Helm release (`{{ .Release.Name }}`). Find the entry with that `name` in [`apps/values.yaml`](../apps/values.yaml), and open the policy under its `path`.

</TabItem>
</Tabs>

### Allow an AWS API

For an AWS API with a VPC endpoint, the pod reaches the endpoint's fixed IPs, which the catalog passes to your chart in `vpcEndpointCidrs`.

If the service has no endpoint yet (it isn't in `endpoint_host_offsets` in the catalog's [`pipelines/network.hcl`](https://github.com/ConsciousML/eks-forge-catalog/blob/main/pipelines/network.hcl)), add one first by following [Add a VPC Endpoint](/docs/iac/add-a-vpc-endpoint/).

Whether or not you added it, check `app_param_key_map` in the same file. If the service isn't there, add it. Its value is the key your chart reads under `vpcEndpointCidrs`.

Then pass `vpcEndpointCidrs.<key>` to your chart by following [Pass Terraform Values to an App](/docs/applications/pass-terraform-values-to-an-app/), reading it from `dependency.vpc_endpoint_cidrs.outputs.vpc_endpoint_cidrs.<key>`. For example, `external-dns-private` in the catalog's [`units/eks/addons/argocd/app_of_apps/terragrunt.hcl`](https://github.com/ConsciousML/eks-forge-catalog/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl):
```hcl
"external-dns-private" = {
  vpcEndpointCidrs = {
    route53 = dependency.vpc_endpoint_cidrs.outputs.vpc_endpoint_cidrs.route53
  }
  ...
}
```

In the same file, also add your key to the `mock_outputs` of the `vpc_endpoint_cidrs` dependency, with dummy IPs. Otherwise, `terragrunt plan` fails until the `endpoint_cidrs` unit is applied:
```hcl
dependency "vpc_endpoint_cidrs" {
  config_path = "../../../../vpc/endpoint_cidrs"
  mock_outputs = {
    vpc_endpoint_cidrs = {
      ...
      route53 = ["10.2.0.11", "10.2.32.11", "10.2.64.11"]
    }
  }
  ...
}
```

In your pod's policy, allow egress to each IP on port `443`. For example, in [`charts/external-dns/templates/network-policy.yaml`](../charts/external-dns/templates/network-policy.yaml):
```yaml
  egress:
    # AWS Route53 API, via the VPC interface endpoint.
    - toCIDR:
        {{- range .Values.vpcEndpointCidrs.route53 }}
        - {{ . }}/32
        {{- end }}
      toPorts:
        - ports:
            - port: "443"
              protocol: TCP
```

## Check Nothing Is Dropped

Push your change and sync again, as in [Deploy the App](#deploy-the-app). Then rerun the command of [Find Dropped Traffic](#find-dropped-traffic). Repeat [Allow Each Dropped Flow](#allow-each-dropped-flow) until it shows no drop to or from your app.

If a flow is still dropped once your rule is synced, see Cilium's [Policy Troubleshooting](https://docs.cilium.io/en/stable/security/policy/troubleshooting/).

## Check the App Works

Then, test that your app behaves as intended, as in [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev). A flow your app didn't send yet, such as a call it only makes on a user action, can still be dropped. If something fails, go back to [Find Dropped Traffic](#find-dropped-traffic).
