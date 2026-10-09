{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Add a Grafana Dashboard

This guide shows you how to add a dashboard to [Grafana](https://grafana.com/oss/), through the values of the `kube-prometheus-stack` chart. You need it when you want to visualize the metrics of an app or a tool. It assumes the metrics are already in Prometheus (see [Monitor a New App](/docs/monitoring/monitor-a-new-app/)), and that you've created a branch in your app of apps fork, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch). It needs no change in your catalog fork.

If you've never opened a Grafana dashboard, follow [Explore Your Metrics](/docs/monitoring/get-started/metrics/) first.

## Add the Folder

Each tool has its own folder in Grafana. If your dashboard goes in one that already exists (e.g. **ArgoCD**), skip to [Add the Dashboard](#add-the-dashboard).

Otherwise, pick a name for it, with only lowercase letters, digits, and hyphens (e.g. `external-dns`). Then, in [`charts/monitoring/kube-prometheus-stack/values.yaml`](../charts/monitoring/kube-prometheus-stack/values.yaml), add a provider under `grafana.dashboardProviders`. Set:
- `name`: the name you picked.
- `folder`: the name of the folder, as shown in Grafana.
- `options.path`: `/var/lib/grafana/dashboards/`, followed by the name you picked.

For example, ExternalDNS's provider:
```yaml
kube-prometheus-stack:
  ...
  grafana:
    ...
    dashboardProviders:
      dashboardproviders.yaml:
        apiVersion: 1
        providers:
          ...
          - name: external-dns
            orgId: 1
            folder: External DNS
            type: file
            options:
              path: /var/lib/grafana/dashboards/external-dns
```

## Add the Dashboard

Pick the tab that fits your dashboard:
- **Published dashboard**: someone already published it, on [grafana.com](https://grafana.com/grafana/dashboards/) or as a JSON file at a URL.
- **Your own dashboard**: you build it yourself in Grafana.

<Tabs groupId="dashboard-source">
<TabItem value="published" label="Published dashboard">

On the dashboard's page on grafana.com, note its ID and its latest revision. Then list the datasources it asks for, replacing `<id>` and `<revision>`:
```bash
curl -sf https://grafana.com/api/dashboards/<id>/revisions/<revision>/download | jq '.__inputs'
```

In the same file, add an entry under `grafana.dashboards`, under the name of your provider. Its key is the name of the dashboard's file, so it must be unique within the folder. Set:
- `gnetId`: the ID of the dashboard.
- `revision`: its revision.
- `datasource`: one entry per input the command printed, with `name` the `name` of the input, and `value` the datasource to use: `Prometheus` or `Loki`. If the command printed `null`, leave `datasource` out.

Add a comment with the URL of its page above. For example, the AWS Load Balancer Controller's dashboard:
```yaml
    dashboards:
      ...
      # https://grafana.com/grafana/dashboards/18319-aws-load-balancer-controller/
      aws-lbc:
        aws-lbc-dashboard:
          gnetId: 18319
          revision: 2
          datasource:
            - { name: DS_PROMETHEUS, value: Prometheus }
```

If the dashboard isn't on grafana.com, replace `gnetId` and `revision` with the `url` of its JSON file, which must be served over HTTPS. For example, one of Karpenter's dashboards:
```yaml
      # https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/#monitoring-with-grafana-optional
      karpenter:
        capacity-dashboard:
          url: https://karpenter.sh/preview/getting-started/getting-started-with-karpenter/karpenter-capacity-dashboard.json
```

</TabItem>
<TabItem value="own" label="Your own dashboard">

Build your dashboard in the Grafana of `dev`, then [export it as JSON](https://grafana.com/docs/grafana/latest/visualizations/dashboards/share-dashboards-panels/). Leave the option that exports it for another instance off, so its panels keep pointing at the `Prometheus` and `Loki` datasources, which have the same name in every environment.

:::warning
Grafana has no persistent volume. A dashboard you build in its UI is lost when its pod is replaced, so export it before you deploy.
:::

In the same file, add an entry under `grafana.dashboards`, under the name of your provider. Its key is the name of the dashboard's file, so it must be unique within the folder. Paste the JSON under its `json` key:
```yaml
    dashboards:
      ...
      <provider>:
        <dashboard>:
          json: |
            {
              "title": "<title>",
              "uid": "<uid>",
              "panels": [...],
              ...
            }
```

To change it later, edit it in Grafana, export it again, and replace the JSON. Grafana doesn't let you save a change to a dashboard that comes from the chart's values.

</TabItem>
</Tabs>

If you added a folder, add its tool to the `# --` comment above `dashboards`, which lists them in the chart's `README.md` (see [Document the Values](/docs/applications/document-a-helm-chart/#document-the-values)).

Grafana's network policy needs no change: it already allows the download of a dashboard from any host over HTTPS.

## Deploy to Dev

Deploy your change to `dev` by following [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev), up to the sync. The sync restarts Grafana's pod, which loads the dashboards when it starts.

## Check the Dashboard

Grafana is only reachable over [Tailscale](/docs/security/tailscale/). Connect by running `tailscale up`, then open `https://grafana.private.dev.<base_domain>` in your browser, replacing `<base_domain>` with your base domain, and log in as in [Log In to Grafana](/docs/monitoring/get-started/metrics/#log-in-to-grafana).

In the left menu, click **Dashboards**, and open your folder. Your dashboard should be listed. Open it, and check that its panels show data. If something is off, see [Troubleshooting](#troubleshooting).

Then open a pull request and merge it, as in [Open a Pull Request](/docs/applications/add-edit-or-remove-an-app/#open-a-pull-request).

To get alerted on the metrics you chart, see [Add an Alert](/docs/monitoring/alerting/add-an-alert/).

## Troubleshooting

If Grafana doesn't answer, or still shows the old dashboards, check that its new pod is running:
```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
```

A pod stuck in `Init` couldn't download a dashboard. If the pod is running but your dashboard is missing, its download failed too. Either way, check its `gnetId` and `revision` by running the `curl` command of [Add the Dashboard](#add-the-dashboard) again, or its `url` by opening it in your browser. The command must print the dashboard's inputs or `null`. If it prints nothing, the ID or the revision is wrong.

If your folder is missing, check that the `options.path` of your provider ends with its `name`, and that your entry under `dashboards` sits under that same name.

If the panels show a datasource error, an input has no entry under `datasource`, or its `value` isn't the exact name of a datasource. If they show **No data**, run one of their queries in Prometheus, as in [Explore Your Metrics](/docs/monitoring/get-started/metrics/). An empty result means the dashboard expects metrics or labels your cluster doesn't have.
