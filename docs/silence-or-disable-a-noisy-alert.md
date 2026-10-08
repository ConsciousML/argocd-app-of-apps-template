{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Silence or Disable a Noisy Alert

This guide shows you how to stop an alert from posting to Slack, either for a while with a [silence](https://prometheus.io/docs/alerting/latest/alertmanager/#silences) in [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/), or for good by disabling its rule. You need it when an alert keeps firing and there's nothing for you to fix.

Pick the one that fits your alert:
- **Silence**: the alert is right, but you can't act on it now (e.g. during a maintenance, or an incident you're already fixing). A silence expires on its own, and changes nothing in your forks.
- **Disable**: the alert is wrong for your cluster, and will never be useful. It's a change in your app of apps fork.

If you've never opened Alertmanager, follow [Follow an Alert](/docs/monitoring/get-started/alerts/) first.

## Silence the Alert

Alertmanager is only reachable over [Tailscale](/docs/security/tailscale/). Connect by running `tailscale up`, then open `https://alertmanager.private.<environment>.<base_domain>` in your browser, replacing `<environment>` with your [environment](/docs/iac/#environments) (e.g. `dev`) and `<base_domain>` with your base domain. Each environment has its own Alertmanager, so a silence only applies to the one you open.

Find your alert in the list, and click its **Silence** button. A form opens, with one matcher per label of the alert.

Under **Matchers**, remove the ones that are too narrow, with the cross next to each. A silence mutes every alert that carries all of its matchers:
- `alertname` alone mutes the alert everywhere it fires.
- `alertname` with `namespace` or `pod` mutes it for that namespace or pod only.

Then set:
- **Duration**: how long the silence lasts (e.g. `2h`). Keep it as short as your maintenance or your fix.
- **Creator**: your name.
- **Comment**: why you silence the alert, with a link to the issue that tracks the fix if there's one.

Click **Preview Alerts** to list the alerts your silence mutes, then **Create**.

The alert keeps firing in Prometheus: only its Slack messages stop. If it still fires when the silence expires, its messages resume.

To end a silence early, click **Silences** in the top menu, find yours, then click **Expire** and **Confirm**.

:::warning
Never silence `Watchdog`. It always fires, and its messages in `#<environment>-watchdog` are how you know alerts still reach Slack.
:::

## Disable the Alert

This part assumes you've created a branch in your app of apps fork, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch). It needs no change in your catalog fork.

### Find Where the Rule Comes From

From the root of your app of apps fork, search for the rule of your alert, replacing `<alert>` with its name (e.g. `KubeCPUOvercommit`):
```bash
grep -rn "alert: <alert>" charts manifests
```

### Disable the Rule

Pick the tab that fits the result:
- **Default rule**: no match, and the `component` label of your alert is `k8s` or `prometheus-stack`. The rule ships with the upstream `kube-prometheus-stack` chart.
- **Standalone rule**: a match under `charts/monitoring/prometheus-rules/`.
- **Upstream chart**: a match in the `values.yaml` of another chart, or no match and another `component` (e.g. `loki`). The rule comes from a chart that wraps an upstream chart as a dependency.

<Tabs groupId="rule-source">
<TabItem value="default" label="Default rule">

In [`charts/monitoring/kube-prometheus-stack/values.yaml`](../charts/monitoring/kube-prometheus-stack/values.yaml), add the name of your alert under `defaultRules.disabled`, with a comment saying why, and a `# --` comment (see [Document the Values](/docs/applications/document-a-helm-chart/#document-the-values)):
```yaml
kube-prometheus-stack:
  ...
  defaultRules:
    # <why this alert is wrong for your cluster>
    # -- Default alerts that are disabled.
    # @section -- Alerting
    disabled:
      <alert>: true
    ...
```

To disable a whole group of default rules instead, set its key to `false` under `defaultRules.rules`. The groups are listed in the upstream chart's [`values.yaml`](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml).

</TabItem>
<TabItem value="standalone" label="Standalone rule">

Delete the rule from the file the search printed, in [`charts/monitoring/prometheus-rules/`](../charts/monitoring/prometheus-rules/), from its `- alert:` line down to the next one.

If it was the last rule of the file, delete the file too, with its bullet under `## What's Inside` in [`charts/monitoring/prometheus-rules/README.md`](../charts/monitoring/prometheus-rules/README.md).

</TabItem>
<TabItem value="upstream" label="Upstream chart">

If the search printed a match, your chart passes the rule to the upstream chart. Delete the rule from the `values.yaml` the search printed, from its `- alert:` line down to the next one. For example, the blackbox exporter's rules are under `prometheusRule.rules`, in [`charts/monitoring/blackbox-exporter/values.yaml`](../charts/monitoring/blackbox-exporter/values.yaml).

If it printed nothing, the upstream chart ships the rule. Find the key that disables one of its alerts in the upstream chart's `values.yaml`, then set it in your chart's `values.yaml`, under the dependency's `name` from your `Chart.yaml`. For example, for one of Loki's alerts, in [`charts/monitoring/loki/values.yaml`](../charts/monitoring/loki/values.yaml):
```yaml
loki:
  ...
  monitoring:
    ...
    alerts:
      enabled: true
      # <why this alert is wrong for your cluster>
      disabled:
        <alert>: true
      ...
```

</TabItem>
</Tabs>

If the alert is only wrong in one environment (e.g. a `dev` cluster too small for it), set the key in the `values-<environment>.yaml` of that environment instead of `values.yaml`, by following [Configure an App per Environment](/docs/applications/configure-an-app-per-environment/). This only works for a key of a chart's values, not for a standalone rule.

### Deploy to Dev

Deploy your change to `dev` by following [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev), up to the sync.

### Check the Rule Is Gone

Prometheus is only reachable over Tailscale too. Open `https://prometheus.private.dev.<base_domain>` in your browser, replacing `<base_domain>` with your base domain. In the top menu, click **Alerts**, and type the name of your alert in the search bar. It should no longer be listed. A removed rule can take a minute to disappear.

If it's still listed, check the spelling of its name, which is case-sensitive, and that your key is nested under the dependency's `name`.

Then open a pull request and merge it, as in [Open a Pull Request](/docs/applications/add-edit-or-remove-an-app/#open-a-pull-request).

To ship your change to `staging` and `prod`, see [Release a Change to Production](/docs/deployment/release-a-change-to-production/).
