# alloy

Deploys [Grafana Alloy](https://grafana.com/docs/alloy/latest/) via the upstream `alloy` chart, as a DaemonSet collecting and forwarding pod logs and Kubernetes cluster events to [Loki](../loki/).

## What's Inside

- **[templates/network-policy.yaml](templates/network-policy.yaml)**: the DaemonSet's `CiliumNetworkPolicy`
