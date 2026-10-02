{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Write Network Policies

This guide shows you how to deny all of an app's network traffic, then allow only what it needs, with [Cilium network policies](https://docs.cilium.io/en/stable/security/policy/). You need it when you add an app, or when traffic to or from an app is dropped. It assumes you've created a branch in your app of apps fork, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch).

If you're new to Cilium network policies, read [How Network Policies Work](/docs/security/how-network-policies-work/) first.

## Deny All Ingress and Egress in Your Namespace

Add your namespace to the `values` list of [`default-deny.yaml`](../manifests/network-policies/cluster-wide/default-deny.yaml). For example, podinfo's namespace:
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
If your app was already running, restart its pods first, so Hubble also sees the traffic they only send on startup.
:::

## Allow Each Dropped Flow

Allow each flow on both ends: as egress for the source, and as ingress for the destination. Otherwise, it's dropped at the other end next. In each rule, the other end is the peer: the destination in the source's egress, and the source in the destination's ingress. Pick the tab that fits each rule:
- **Several namespaces**: the rule applies to the pods of several namespaces (e.g. resolving DNS).
- **One pod**: the rule applies to a single pod (e.g. Prometheus scraping your app).

<Tabs groupId="policy-scope">
<TabItem value="namespaces" label="Several namespaces">

Add your namespace to the `values` list of the file in [`manifests/network-policies/cluster-wide/`](../manifests/network-policies/cluster-wide/) that allows the flow, as in [Deny All Ingress and Egress in Your Namespace](#deny-all-ingress-and-egress-in-your-namespace):
- [`kube-dns-egress.yaml`](../manifests/network-policies/cluster-wide/kube-dns-egress.yaml): resolving DNS names.
- [`kube-apiserver-egress.yaml`](../manifests/network-policies/cluster-wide/kube-apiserver-egress.yaml): calling the Kubernetes API.
- [`eks-pod-identity-egress.yaml`](../manifests/network-policies/cluster-wide/eks-pod-identity-egress.yaml): getting AWS credentials through an [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) association.

For example, if your app resolves DNS names, like podinfo, add its namespace to [`kube-dns-egress.yaml`](../manifests/network-policies/cluster-wide/kube-dns-egress.yaml):
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

If no file allows the flow, add a new `CiliumClusterwideNetworkPolicy` there, one per concern, selecting namespaces the same way (see Cilium's [CiliumClusterwideNetworkPolicy](https://docs.cilium.io/en/stable/network/kubernetes/policy/#ciliumclusterwidenetworkpolicy)). For example, [`kube-apiserver-egress.yaml`](../manifests/network-policies/cluster-wide/kube-apiserver-egress.yaml):
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
<TabItem value="pod" label="One pod">

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

</TabItem>
</Tabs>

### Find the Peer's Policy

If the other end is an existing pod, add its side of the rule to its policy. In [`apps/values.yaml`](../apps/values.yaml), find the entry whose `destination.namespace` is the peer's namespace, and whose name matches the peer's pod name (e.g. `kube-prometheus-stack` for `prometheus-kube-prometheus-stack-prometheus-0`). If no entry matches, as for ArgoCD or CoreDNS, take the one whose name contains `network-policies`. The policy is a `*network-policy*.yaml` file under its `path`.

:::warning
If a drop shows `world` where you expect a pod, that pod may have started before Cilium's agent on its node, so Cilium doesn't manage it. Restart it, or run [`scripts/restart-missing-cilium-endpoints.sh`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/scripts/restart-missing-cilium-endpoints.sh) from the root of your catalog fork, then look for drops again.
:::

### Match the Peer

In either kind of policy, match the other end of the flow with one of the selectors below, under `egress` in the source's policy, and under `ingress` in the destination's. Each rule also restricts the port with `toPorts`. These are the selectors EKS Forge uses today, not every one Cilium offers. For a peer they don't fit, see Cilium's [Layer 3](https://docs.cilium.io/en/stable/security/policy/layer3/) and [Layer 4](https://docs.cilium.io/en/stable/security/policy/layer4/) policy docs.

| Peer | Egress, in the source | Ingress, in the destination | Cilium docs | Example |
|------|-----------------------|-----------------------------|-------------|---------|
| A pod in the same namespace | `toEndpoints` on its labels | `fromEndpoints` on its labels | [Endpoints Based](https://docs.cilium.io/en/stable/security/policy/layer3/#endpoints-based) | [`k6-loadtest-network-policy.yaml`](../manifests/podinfo/k6-loadtest-network-policy.yaml) |
| A pod in another namespace | Same, plus `io.kubernetes.pod.namespace` | Same, plus `io.kubernetes.pod.namespace` | [Endpoints Based](https://docs.cilium.io/en/stable/security/policy/layer3/#endpoints-based) | [`network-policy-results-cache.yaml`](../charts/monitoring/loki/templates/network-policy-results-cache.yaml) |
| The Kubernetes API | `toEntities: [kube-apiserver]` | N/A | [Entities Based](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) | [`kube-apiserver-egress.yaml`](../manifests/network-policies/cluster-wide/kube-apiserver-egress.yaml) |
| The kubelet, probing your pod | N/A | `fromEntities: [host]` | [Entities Based](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) | [`podinfo-network-policy.yaml`](../manifests/podinfo/podinfo-network-policy.yaml) |
| The EKS Pod Identity agent | `toEntities: [host]` | N/A | [Entities Based](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) | [`eks-pod-identity-egress.yaml`](../manifests/network-policies/cluster-wide/eks-pod-identity-egress.yaml) |
| A load balancer, forwarding to your pod | N/A | `fromEntities: [world]` | [Entities Based](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) | [`podinfo-network-policy.yaml`](../manifests/podinfo/podinfo-network-policy.yaml) |
| An AWS API with a VPC endpoint | `toCIDR` on `vpcEndpointCidrs` | N/A | [IP/CIDR Based](https://docs.cilium.io/en/stable/security/policy/layer3/#cidr-based) | [`charts/external-dns/templates/network-policy.yaml`](../charts/external-dns/templates/network-policy.yaml) |
| S3, or anything outside AWS | `toEntities: [world]` | N/A | [Entities Based](https://docs.cilium.io/en/stable/security/policy/layer3/#entities-based) | [`network-policy-single-binary.yaml`](../charts/monitoring/loki/templates/network-policy-single-binary.yaml) |

For an AWS API, the catalog injects the endpoint's IPs in `vpcEndpointCidrs`, see [Pass Terraform Values to an App](/docs/applications/pass-terraform-values-to-an-app/). If the service has no endpoint yet, add it to `endpoint_host_offsets` and `app_param_key_map` in the catalog's [`pipelines/network.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/pipelines/network.hcl).

:::warning
Only [Layer 3](https://docs.cilium.io/en/stable/security/policy/layer3/) and [Layer 4](https://docs.cilium.io/en/stable/security/policy/layer4/) rules work. Cilium doesn't support [Layer 7](https://docs.cilium.io/en/stable/security/policy/layer7/) rules (e.g. HTTP paths) when chained to the AWS VPC CNI, as in EKS Forge (see Cilium's [AWS VPC CNI chaining](https://docs.cilium.io/en/stable/installation/cni-chaining-aws-cni/) limitations). [`toFQDNs`](https://docs.cilium.io/en/stable/security/policy/layer3/#dns-based) doesn't work either, since it needs a Layer 7 DNS rule.
:::

## Check Nothing Is Dropped

Push your change and sync again, as in [Deploy the App](#deploy-the-app). Then rerun the command of [Find Dropped Traffic](#find-dropped-traffic). Repeat [Allow Each Dropped Flow](#allow-each-dropped-flow) until it shows no drop to or from your app.

If a flow is still dropped once your rule is synced, see Cilium's [Policy Troubleshooting](https://docs.cilium.io/en/stable/security/policy/troubleshooting/).

## Check the App Works

Then, test that your app behaves as intended, as in [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev). A flow your app didn't send yet, such as a call it only makes on a user action, can still be dropped. If something fails, go back to [Find Dropped Traffic](#find-dropped-traffic).
