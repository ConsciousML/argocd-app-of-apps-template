# guestbook

Demo app used to verify an end to end deploy. Plain Kubernetes manifests, not a Helm chart.

## Integration

- **[`guestbook-httproute`](../helm-httproute/guestbook-httproute-values.yaml)**: an instance of the generic [`helm-httproute`](../helm-httproute) chart, exposes this app's `Service` through the public `Gateway`
