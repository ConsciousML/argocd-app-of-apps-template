# `gateway-class` Helm Chart Reference

The [`gateway-class` chart](./) renders a `GatewayClass` implemented by the AWS Load Balancer Controller.

For setup steps, read [How to Expose an App](https://eks-forge.readthedocs.io/latest/docs/applications/expose-an-app/).

## What's Inside

- **[templates/gateway_class.yaml](templates/gateway_class.yaml)**: the `GatewayClass`
- **[values.yaml](values.yaml)**: see [Values](#values)

## Values

### GatewayClass

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| gatewayClassName | string | `"aws-alb"` | `GatewayClass` name. Also loaded by both [`gateway`](../gateway) instances via `extraValueFiles`. |
| controllerName | string | `"gateway.k8s.aws/alb"` | Controller implementing this class, the AWS Load Balancer Controller. |

## Upstream Dependencies

- **[`aws-lbc`](../../aws-lbc)**: this entry depends on it even though nothing in the manifest references it. The `GatewayClass` only reports `Healthy` once the controller sets its `Accepted` condition
