# podinfo

Sample app ([stefanprodan/podinfo](https://github.com/stefanprodan/podinfo)) used to verify an end-to-end deploy, meant to be swapped for a real app in a fork. Exposes `/metrics`, scraped via the bundled `ServiceMonitor`.

Also demos an HPA on CPU, see [Load Testing](../../docs/load-testing.md).

## What's Inside

- **[podinfo-deployment.yaml](podinfo-deployment.yaml)**: the app itself
- **[podinfo-svc.yaml](podinfo-svc.yaml)**: `ClusterIP` service, fronts the deployment
- **[podinfo-network-policy.yaml](podinfo-network-policy.yaml)**: `CiliumNetworkPolicy`, ingress from the ALB, kubelet probes, and Prometheus
- **[podinfo-servicemonitor.yaml](podinfo-servicemonitor.yaml)**: tells `kube-prometheus-stack` to scrape `/metrics`
- **[podinfo-hpa.yaml](podinfo-hpa.yaml)**: `HorizontalPodAutoscaler` on CPU, the load-testing demo target
- **[k6-loadtest-cronjob.yaml](k6-loadtest-cronjob.yaml)**: suspended `CronJob`, triggers a k6 run on demand
- **[k6-loadtest-script.yaml](k6-loadtest-script.yaml)**: `ConfigMap` holding the k6 script the CronJob runs
