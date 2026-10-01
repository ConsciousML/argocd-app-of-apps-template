<!-- This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/docs/reference/manifests/network-policies/cluster-wide/. It is not meant to be read directly in this repository. -->

# `network-policies-cluster-wide` Manifests Reference

The [`network-policies-cluster-wide` manifests](./) define `CiliumClusterwideNetworkPolicy` rules, one file per concern. Each `endpointSelector` lists the namespaces it applies to directly:

```yaml
endpointSelector:
  matchExpressions:
    - key: io.kubernetes.pod.namespace
      operator: In
      values:
        - <namespace_name_1>
        - <namespace_name_2>
```

## What's Inside

- **[default-deny.yaml](default-deny.yaml)**: `enableDefaultDeny` for both directions, for every opted-in namespace
- **[kube-apiserver-egress.yaml](kube-apiserver-egress.yaml)**: egress to the API server, for namespaces that talk to it
- **[kube-dns-egress.yaml](kube-dns-egress.yaml)**: egress to `kube-dns`, for namespaces that resolve DNS
- **[eks-pod-identity-egress.yaml](eks-pod-identity-egress.yaml)**: egress to the EKS Pod Identity credential endpoint, for namespaces with pods using an EKS Pod Identity association

## Onboarding a Namespace

<!-- MIGRATE: how-to, move to the site's how-to guides -->
Onboarding a namespace means adding it to the relevant file's `values` list. `default-deny.yaml` takes every opted-in namespace, the others only where needed.

## History

<!-- MIGRATE: explanation, move to the site's explanation docs -->
`default-deny.yaml` replaces the per-namespace default-deny `CiliumNetworkPolicy` files.
