# helm-goldilocks

[Goldilocks](https://goldilocks.docs.fairwinds.com/) dashboard, reads `VerticalPodAutoscaler` recommendations and summarizes them per workload for resource-sizing visibility. Creates VPAs for every workload controller in every namespace (`controller.on-by-default: true`), no per-namespace labeling needed.

## What's Inside

- **[values.yaml](values.yaml)**: disables the bundled `vpa` and `metrics-server` subcharts (installed separately, see Upstream Dependencies), enables the controller in `on-by-default` mode and the dashboard
- **`goldilocks-httproute`** (app-of-apps): an instance of the generic [`helm-httproute`](https://github.com/ConsciousML/argocd-app-of-apps-template/tree/main/helm-httproute) chart, exposes the dashboard

## Upstream Dependencies

- **[`helm-vpa`](../helm-vpa/)**: the VPA recommender and CRD that Goldilocks reads recommendations from
- **EKS `metrics-server` addon** ([terragrunt-template-catalog-eks](https://github.com/ConsciousML/terragrunt-template-catalog-eks)): required by the VPA recommender, not by Goldilocks directly
