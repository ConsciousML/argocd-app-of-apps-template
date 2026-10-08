{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Monitor a New App

This guide shows you how to have [Prometheus](https://prometheus.io/) scrape your app's metrics, with a [`ServiceMonitor`](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.ServiceMonitor) or a [`PodMonitor`](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.PodMonitor). You need it when your app exposes Prometheus metrics (e.g. on `/metrics`). It's one of the [Extra Steps](/docs/applications/add-edit-or-remove-an-app/#extra-steps) of adding or editing an app, and assumes you've created a branch in your app of apps fork, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch). It needs no change in your catalog fork.

If you've never queried Prometheus, follow [Explore Your Metrics](/docs/monitoring/get-started/metrics/) first.

## Add the Monitor

Pick the tab that fits your app:
- **Own manifests or chart**: you write its resources, as plain manifests or as the templates of your own chart.
- **Upstream chart**: your chart wraps an upstream chart as a dependency, and the upstream chart creates its resources.

<Tabs groupId="app-type">
<TabItem value="own" label="Own manifests or chart">

Add a `ServiceMonitor` next to your app's files: in `manifests/<name>/` for plain manifests, or in `templates/` for a Helm chart. Set:
- `selector`: the labels of your app's [`Service`](https://kubernetes.io/docs/concepts/services-networking/service/), not its pods'.
- `endpoints`: one entry per port to scrape, with `port` the name of the `Service` port, and `path` the path your app serves its metrics on.

For example, [`manifests/podinfo/podinfo-servicemonitor.yaml`](../manifests/podinfo/podinfo-servicemonitor.yaml) scrapes the `http` port of podinfo's `Service`:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: podinfo
spec:
  selector:
    matchLabels:
      app: podinfo
  endpoints:
    - port: http
      path: /metrics
```

It needs no label of its own: Prometheus picks up every `ServiceMonitor` and `PodMonitor` in the cluster, whatever their labels (see the [`kube-prometheus-stack` Helm Chart](/docs/reference/helm_charts/monitoring/kube-prometheus-stack/) reference).

If your app has no `Service` (e.g. a background worker), add a `PodMonitor` instead. Set its `selector` to the labels of your app's pods, and replace `endpoints` with `podMetricsEndpoints`, where `port` is the name of the container port:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: <app>
spec:
  selector:
    matchLabels:
      app: <app>
  podMetricsEndpoints:
    - port: <port-name>
      path: /metrics
```

</TabItem>
<TabItem value="upstream" label="Upstream chart">

Most upstream charts ship their own monitor, disabled by default. Find its key in the upstream chart's `values.yaml`, usually `serviceMonitor.enabled` or `podMonitor.enabled`. Then enable it in your chart's `values.yaml`, under the dependency's `name` from your `Chart.yaml`, with a `# --` comment (see [Document the Values](/docs/applications/document-a-helm-chart/#document-the-values)).

For example, ExternalDNS's `ServiceMonitor`, in [`charts/external-dns/values.yaml`](../charts/external-dns/values.yaml):
```yaml
external-dns:
  ...
  # -- Enables the Prometheus `ServiceMonitor`.
  # @section -- ExternalDNS
  serviceMonitor:
    enabled: true
```

For a `PodMonitor`, see the `recommender` key in [`charts/right-sizing/vpa/values.yaml`](../charts/right-sizing/vpa/values.yaml).

If the upstream chart ships no monitor, add one to your chart's `templates/`, as in the **Own manifests or chart** tab.

</TabItem>
</Tabs>

## Allow Prometheus to Scrape

Your namespace denies all traffic by default, so allow Prometheus to reach your app. If your app has no network policy yet, follow [Write Network Policies](/docs/security/write-network-policies/) first.

In your app's `CiliumNetworkPolicy`, allow ingress from Prometheus on the container port your metrics are served on, not the `Service` port. For example, in [`manifests/podinfo/podinfo-network-policy.yaml`](../manifests/podinfo/podinfo-network-policy.yaml):
```yaml
  ingress:
    ...
    # kube-prometheus-stack scraping /metrics (ServiceMonitor).
    - fromEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: monitoring
            app.kubernetes.io/name: prometheus
      toPorts:
        - ports:
            - port: "9898"
              protocol: TCP
```

Prometheus's own policy needs no change, since it already allows egress to every pod in the cluster.

## Deploy to Dev

Deploy your change to `dev` by following [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev), up to the sync.

## Check the Target

Prometheus is only reachable over [Tailscale](/docs/security/tailscale/). Connect by running `tailscale up`, then open `https://prometheus.private.dev.<base_domain>` in your browser, replacing `<base_domain>` with your base domain. Run this query, replacing `<namespace>` with your app's namespace:
```promql
up{namespace="<namespace>"}
```

You should get one result per pod of your app, each with the value `1`. A new monitor can take a minute to show up.

If the query returns nothing, your monitor selects no target. Check that its `selector` matches the labels of your `Service` (or of your pods, for a `PodMonitor`), and that its `port` is the name of a port, not its number:
```bash
kubectl get service,pods -n <namespace> --show-labels
```

If a result shows `0`, Prometheus found the target but can't scrape it. Most often, a network policy is dropping the scrape. See [Find Dropped Traffic](/docs/security/write-network-policies/#find-dropped-traffic).

Then open a pull request and merge it, as in [Open a Pull Request](/docs/applications/add-edit-or-remove-an-app/#open-a-pull-request).

To chart your metrics, see [Add a Grafana Dashboard](/docs/monitoring/add-a-grafana-dashboard/). To get alerted on them, see [Add an Alert](/docs/monitoring/alerting/add-an-alert/).
