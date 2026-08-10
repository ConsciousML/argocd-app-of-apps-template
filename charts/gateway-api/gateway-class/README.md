# gateway-class

Defines a `GatewayClass` implemented by the AWS Load Balancer Controller.

Both `gateway-public` and `gateway-private` instances of [`gateway`](../gateway) load this chart's `values.yaml` via `extraValueFiles` to reference the same `gatewayClassName`.

## Upstream Dependencies

- **[`aws-lbc`](../../aws-lbc)**: this entry depends on it even though nothing in the manifest references it. The `GatewayClass` only reports `Healthy` once the controller sets its `Accepted` condition
