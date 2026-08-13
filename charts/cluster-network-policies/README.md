# cluster-network-policies

Admin and Baseline tier [`ClusterNetworkPolicy`](https://docs.aws.amazon.com/eks/latest/userguide/cni-network-policy.html) rules every namespace needs regardless of its own `NetworkPolicy`. Enforced by the `vpc-cni` EKS addon's `enableNetworkPolicy`, not Cilium, which only observes traffic here (see [Hubble UI](../cilium/README.md)).

## What's Inside

- **[templates/deny-imds-egress.yaml](templates/deny-imds-egress.yaml)**: blocks the instance metadata endpoint
- **[templates/allow-dns-egress.yaml](templates/allow-dns-egress.yaml)**: allows CoreDNS lookups
- **[templates/allow-pod-identity-egress.yaml](templates/allow-pod-identity-egress.yaml)**: allows the Pod Identity Agent's link-local endpoint
- **[templates/allow-apiserver-egress.yaml](templates/allow-apiserver-egress.yaml)**: allows the `kubernetes.default` API server
- **[values.yaml](values.yaml)**: `apiServerCidr` is a placeholder. The catalog's [`app_of_apps` unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl) injects the real value via `appParams.network-policies-cluster-wide` at sync time
