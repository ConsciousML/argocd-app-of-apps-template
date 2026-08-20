# vpa

Recommender-only install of the Kubernetes [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler), source data for [Goldilocks](../goldilocks/). `updater` and `admissionController` are disabled, so it only writes recommendations to each `VerticalPodAutoscaler`'s `status`, it never evicts or resizes running pods.

## What's Inside

- **[values.yaml](values.yaml)**: enables the recommender only, disables the updater, the admission controller, and the bundled metrics-server subchart
- **[templates/network-policy.yaml](templates/network-policy.yaml)**: the recommender's `CiliumNetworkPolicy`

## Upstream Dependencies

- **EKS `metrics-server` addon** ([terragrunt-template-catalog-eks](https://github.com/ConsciousML/terragrunt-template-catalog-eks)): the recommender hard-depends on it for live resource usage
