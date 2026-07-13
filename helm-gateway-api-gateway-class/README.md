# helm-gateway-api-gateway-class

Defines a `GatewayClass` implemented by the AWS Load Balancer Controller.

## Integration

- **[`helm-gateway-api-gateway`](../helm-gateway-api-gateway)**: loads this chart's `values.yaml` via `extraValueFiles` to reference the same `gatewayClassName`
- **[`helm-aws-lbc`](../helm-aws-lbc)**: this entry depends on it even though nothing in the manifest references it. The `GatewayClass` only reports `Healthy` once the controller sets its `Accepted` condition
