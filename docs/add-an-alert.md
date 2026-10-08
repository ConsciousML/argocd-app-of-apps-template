{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Add an Alert

This guide shows you how to add an alert with a [`PrometheusRule`](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.PrometheusRule), and get its notification in Slack. You need it when you want to be notified that a metric meets a condition (e.g. an app is down). It assumes the metric is already in Prometheus (see [Monitor a New App](/docs/monitoring/monitor-a-new-app/)), and that you've created a branch in your app of apps fork, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch). It needs no change in your catalog fork.

If you've never seen an alert reach Slack, follow [Follow an Alert](/docs/monitoring/get-started/alerts/) first.

## Pick the Labels

Your alert lands in the `#<environment>-<component>-<severity>` channel, so pick its two labels first:
- `component`: one of `k8s`, `prometheus-stack`, `loki`, `argocd`, or `uptime`. If none fits what your alert watches, give it its own channels by following [Add an Alert Route & Slack Channel](/docs/monitoring/alerting/add-an-alert-route-and-slack-channel/) first. Without a route, your alert lands in `#<environment>-unrouted`.
- `severity`: `critical` or `warning`. An alert with `info` or `none` is never sent to Slack.

## Write the Rule

First, write the expression of your alert and run it in Prometheus, as in [Explore Your Metrics](/docs/monitoring/get-started/metrics/). It must return a result only while something is wrong.

Then pick the tab that fits where your alert goes:
- **Standalone rule**: you write the rule yourself, in a `PrometheusRule` manifest.
- **Upstream chart**: your chart wraps an upstream chart as a dependency, and the upstream chart ships its own alerts or renders the rules you pass it.

<Tabs groupId="rule-source">
<TabItem value="standalone" label="Standalone rule">

Add your rule to the file of its component in [`charts/monitoring/prometheus-rules/`](../charts/monitoring/prometheus-rules/), under one of its `groups`. If your component has no file yet, create `<component>.yaml` there. Set:
- `alert`: the name of the alert, shown in the title of the Slack message.
- `expr`: your expression.
- `for`: how long the expression must keep returning a result before the alert fires.
- `labels`: the `severity` and `component` you picked.
- `annotations`: a `summary` and a `description`, which make the body of the Slack message.

For example, the first alert of [`argocd.yaml`](../charts/monitoring/prometheus-rules/argocd.yaml):
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: argocd-mixin
spec:
  groups:
    - name: argo-cd
      rules:
        - alert: ArgoCdAppSyncFailed
          annotations:
            description: "The application {{ $labels.dest_server }}/{{ $labels.project }}/{{ $labels.name }} has failed to sync with the status {{ $labels.phase }} the past 10m."
            summary: "An ArgoCD Application has Failed to Sync."
          expr: |
            sum(
              round(
                increase(
                  argocd_app_sync_total{
                    job=~"(argocd|argo-cd).*",
                    phase!="Succeeded"
                  }[10m]
                )
              )
            ) by (cluster, job, dest_server, project, name, phase) > 0
          for: 1m
          labels:
            severity: warning
            component: argocd
        ...
```

The `PrometheusRule` needs no label of its own: Prometheus loads every one in the cluster, whatever its labels (see the [`kube-prometheus-stack` Helm Chart](/docs/reference/helm_charts/monitoring/kube-prometheus-stack/) reference).

If you created a file, add its bullet under `## What's Inside` in [`charts/monitoring/prometheus-rules/README.md`](../charts/monitoring/prometheus-rules/README.md), saying where its rules come from and which `component` they carry.

</TabItem>
<TabItem value="upstream" label="Upstream chart">

Find how the upstream chart handles alerts in its `values.yaml`, then set the keys in your chart's `values.yaml`, under the dependency's `name` from your `Chart.yaml`, with a `# --` comment (see [Document the Values](/docs/applications/document-a-helm-chart/#document-the-values)).

If the upstream chart ships its own alerts, enable them, and set your `component` through the key that adds labels to every alert. They already carry a `severity`. For example, Loki's alerts, in [`charts/monitoring/loki/values.yaml`](../charts/monitoring/loki/values.yaml):
```yaml
loki:
  ...
  monitoring:
    ...
    alerts:
      enabled: true
      additionalRuleLabels:
        component: loki
```

If the upstream chart renders the rules you pass it instead, write yours under its key, with both labels on each rule. For example, the blackbox exporter's first alert, in [`charts/monitoring/blackbox-exporter/values.yaml`](../charts/monitoring/blackbox-exporter/values.yaml):
```yaml
prometheus-blackbox-exporter:
  ...
  prometheusRule:
    enabled: true
    ...
    rules:
      - alert: EndpointDown
        expr: probe_success == 0
        for: 5m
        labels: { severity: critical, component: uptime }
        annotations:
          summary: "{{ $labels.target }} is unreachable"
          description: "Probe to {{ $labels.target }} has failed for 5m."
      ...
```

:::warning
A key such as `prometheusRule.additionalLabels` only labels the `PrometheusRule` object, not its alerts. Alertmanager never sees it, so the alerts land in `#<environment>-unrouted`.
:::

If the upstream chart does neither, write your rule as in the **Standalone rule** tab.

</TabItem>
</Tabs>

## Deploy to Dev

Deploy your change to `dev` by following [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev), up to the sync.

## Check the Rule

Prometheus is only reachable over [Tailscale](/docs/security/tailscale/). Connect by running `tailscale up`, then open `https://prometheus.private.dev.<base_domain>` in your browser, replacing `<base_domain>` with your base domain. In the top menu, click **Alerts**, and type the name of your alert in the search bar.

Click your alert to expand it, and check that it shows your `component` and `severity` labels. A new rule can take a minute to show up.

If your alert isn't listed, check that its `PrometheusRule` exists in the cluster:
```bash
kubectl get prometheusrules -A
```

If it's missing, its Application didn't sync it. Run `argocd app get <app>`, replacing `<app>` with the Application that deploys it (`prometheus-rules` for a standalone rule), and fix the error it shows.

## Check the Notification

To see the message your alert sends, make it fire in `dev`. Pick the tab that fits your alert:
- **Produce the condition**: you can make what your alert watches go wrong in `dev` (e.g. an app that's down).
- **Change the condition**: you can't, or not quickly enough (e.g. a certificate that expires in 30 days).

Either way, mark your temporary change with a `TEMP:` comment, which CI rejects if you forget to remove it.

<Tabs groupId="alert-test">
<TabItem value="produce" label="Produce the condition">

Break what your alert watches on your branch, not with `kubectl`: ArgoCD reverts any change made by hand in the cluster. For example, for an alert that fires when an app has no running pod, scale its `Deployment` to zero:
```yaml
spec:
  # TEMP: stops the app so the alert fires, revert before merging.
  replicas: 0
```

This checks your expression too, not only where the alert lands.

</TabItem>
<TabItem value="change" label="Change the condition">

Change the expression of your alert so it holds now (e.g. a threshold your app already exceeds):
```yaml
          # TEMP: fires on purpose, revert before merging.
          expr: <expression-that-holds-now>
```

This only checks where the alert lands, not your real expression.

</TabItem>
</Tabs>

Push and sync again, as in [Deploy to Dev](#deploy-to-dev). Once the condition has held for the duration of `for`, a message with this title should show up in `#dev-<component>-<severity>`:
```text
[FIRING:1] <alert> (<severity>)
```

If the message shows up in `#dev-unrouted` instead, no route matches its labels. Check the spelling of your `component`, and that it has a route (see [Add an Alert Route & Slack Channel](/docs/monitoring/alerting/add-an-alert-route-and-slack-channel/)). If no message shows up at all, check that your `severity` is `critical` or `warning`.

Then revert your temporary change with its `TEMP:` comment, and push and sync once more. A `[RESOLVED]` message follows in the same channel.

Finally, open a pull request and merge it, as in [Open a Pull Request](/docs/applications/add-edit-or-remove-an-app/#open-a-pull-request).

If your alert fires too often, see [Silence or Disable a Noisy Alert](/docs/monitoring/alerting/silence-or-disable-a-noisy-alert/).
