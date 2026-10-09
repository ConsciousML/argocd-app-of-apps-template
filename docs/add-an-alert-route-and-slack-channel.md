{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

# How to Add an Alert Route & Slack Channel

This guide shows you how to send the alerts of a new `component` to their own Slack channels, one per severity. You need it when an alert fits none of the existing components (`k8s`, `prometheus-stack`, `loki`, `argocd`, and `uptime`), since [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) sends it to `#<environment>-unrouted` otherwise. It assumes you've created a branch in both forks, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch).

First, pick a name for your component, with only lowercase letters, digits, and hyphens (e.g. `uptime`). It ends up in the name of its channels, `<environment>-<component>-critical` and `<environment>-<component>-warning`.

## In Your Catalog Fork

### Add the Channel Names

Add one name per severity to `channel_names` in [`pipelines/bootstrap/slack/channels.hcl`](https://github.com/ConsciousML/eks-forge-catalog/blob/main/pipelines/bootstrap/slack/channels.hcl), without the environment or a leading `#`. For example, for `uptime`:
```hcl
locals {
  channel_names = [
    ...
    "uptime-critical",
    "uptime-warning",
    ...
  ]
}
```

### Create the Channels

From the root of your catalog fork, apply the [Slack bootstrap](/docs/quickstart/bootstrap/slack/) pipeline again. It creates the two channels for each environment that has a folder under `pipelines/bootstrap/slack/channels/`:
```bash
source .env
cd pipelines/bootstrap/slack
terragrunt stack clean
terragrunt stack generate
terragrunt run --all apply --backend-bootstrap --non-interactive --no-stack-generate
```

The bot is a member of the channels it creates, but you aren't. Join them in your Slack workspace, as in [Slack Bootstrap](/docs/quickstart/bootstrap/slack/).

## In Your App of Apps Fork

### Add the Receivers

In [`charts/monitoring/kube-prometheus-stack/values.yaml`](../charts/monitoring/kube-prometheus-stack/values.yaml), add one receiver per severity under `alertmanager.config.receivers`. Set its `channel` to `#{{ .Values.environment }}-`, followed by the name you added to `channels.hcl`. The two must match exactly, or Alertmanager posts to a channel that doesn't exist. For example, for `uptime`:
```yaml
kube-prometheus-stack:
  ...
  alertmanager:
    ...
    config:
      ...
      receivers:
        ...
        - name: "uptime-critical"
          slack_configs:
            - channel: "#{{ .Values.environment }}-uptime-critical"
              send_resolved: true
        - name: "uptime-warning"
          slack_configs:
            - channel: "#{{ .Values.environment }}-uptime-warning"
              send_resolved: true
```

### Add the Routes

In the same file, add one route per severity under `alertmanager.config.route.routes`, each matching your `component` and its `severity`, and naming its receiver. Add them after the existing ones: Alertmanager stops at the first route that matches, and the `Watchdog` and `info|none` routes must stay first. For example, for `uptime`:
```yaml
      route:
        receiver: "unrouted"
        routes:
          ...
          - receiver: "uptime-critical"
            matchers:
              - component = "uptime"
              - severity = "critical"
          - receiver: "uptime-warning"
            matchers:
              - component = "uptime"
              - severity = "warning"
```

## Deploy to Dev

Deploy your change to `dev` by following [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev), up to the sync.

## Check the Route

On the same branch, add an alert that carries your `component`, by following [Add an Alert](/docs/monitoring/alerting/add-an-alert/), including [Check the Notification](/docs/monitoring/alerting/add-an-alert/#check-the-notification). Its message should show up in `#dev-<component>-<severity>`.

If it shows up in `#dev-unrouted` instead, no route matches. Check that the `component` in your matchers is spelled as in the labels of your alert.

If it never shows up, Alertmanager's logs say why, most often a channel that doesn't exist or whose name differs from the receiver's `channel`:
```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager -c alertmanager
```

## Open a Pull Request and Merge

Follow [Open a Pull Request](/docs/applications/add-edit-or-remove-an-app/#open-a-pull-request) and [Merge](/docs/applications/add-edit-or-remove-an-app/#merge), for both forks.

## Ship the Route to Staging and Prod

Follow [Release a Change to Production](/docs/deployment/release-a-change-to-production/), with both [Release an IaC Change](/docs/iac/release-an-iac-change/) and [Release an App Change](/docs/applications/release-an-app-change/) in the same pull request.

Your live fork has its own list of channels. In the [Update the Bootstrap Pipelines](/docs/iac/release-an-iac-change/#update-the-bootstrap-pipelines) step, add the same names to [`live/bootstrap/slack/channels.hcl`](https://github.com/ConsciousML/eks-forge-live/blob/main/live/bootstrap/slack/channels.hcl). Its apply creates the `staging-` and `prod-` channels, which you then join. Without them, Alertmanager posts the alerts of your component to channels that don't exist in `staging` and `prod`.
