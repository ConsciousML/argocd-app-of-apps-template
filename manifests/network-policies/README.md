# network-policies

One default-deny [`NetworkPolicy`](https://kubernetes.io/docs/concepts/services-networking/network-policies/) per addon namespace, empty `podSelector` covers every pod. Enforced by the `vpc-cni` EKS addon's `enableNetworkPolicy`, not Cilium, which only observes traffic here (see [Hubble UI](../../charts/cilium/README.md)).

Allow rules for a component's actual traffic live alongside its chart instead, in `templates/networkpolicy-allow.yaml`. Rules every namespace needs regardless of its own policy live in [`cluster-network-policies`](../../charts/cluster-network-policies) instead, since a namespace's own `NetworkPolicy` stops Baseline tier `ClusterNetworkPolicy` rules from applying to it.
