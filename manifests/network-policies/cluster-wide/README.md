# network-policies/cluster-wide

`CiliumClusterwideNetworkPolicy`, one file per concern, each `endpointSelector` listing the namespaces it applies to directly:

```yaml
endpointSelector:
  matchExpressions:
    - key: io.kubernetes.pod.namespace
      operator: In
      values:
        - <namespace_name_1>
        - <namespace_name_2>
```

Onboarding a namespace means adding it to the relevant file's `values` list.

## What's Inside

- **[default-deny.yaml](default-deny.yaml)**: `enableDefaultDeny` for both directions, replacing the per-namespace default-deny `CiliumNetworkPolicy` files
- **[kube-apiserver-egress.yaml](kube-apiserver-egress.yaml)**: egress to the API server, for namespaces that talk to it
- **[kube-dns-egress.yaml](kube-dns-egress.yaml)**: egress to `kube-dns`, for namespaces that resolve DNS
- **[eks-pod-identity-egress.yaml](eks-pod-identity-egress.yaml)**: egress to the EKS Pod Identity credential endpoint, for namespaces with pods using an EKS Pod Identity association

Only `default-deny.yaml` is universal, the others are listed only where needed.
