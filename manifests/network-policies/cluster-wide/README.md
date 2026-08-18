# network-policies/cluster-wide

`CiliumClusterwideNetworkPolicy`, one file per concern. Each is matched by its own `network-policy.<name>: "true"` label on the target Namespace (see `manifests/namespaces`), not one shared label, so a namespace opts into exactly what it needs.

Cilium mirrors Namespace labels onto every pod's identity as `k8s:io.kubernetes.pod.namespace.labels.<key>`, so `endpointSelector` can match on it without touching any chart's `podLabels`.

`default-deny` sets `enableDefaultDeny` for both directions with no rule lists. It replaces per-namespace default-deny `CiliumNetworkPolicy` files.

`kube-apiserver-egress` and `kube-dns-egress` cover the egress a default-deny namespace needs if it talks to the API server or resolves DNS. Not every namespace does. `podinfo` is pure inbound, so it only carries `default-deny`.

Ingress from `host` (kubelet probes) stays out of here on purpose. It's scoped per workload to the actual probe port instead of granting the `host` entity blanket access to every port, since no port is shared across components.
