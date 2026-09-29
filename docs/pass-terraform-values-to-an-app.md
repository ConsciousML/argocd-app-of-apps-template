{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Pass Terraform Values to an App

This guide shows you how to pass a value from the catalog to an app, through [`appParams`](/docs/applications/how-the-app-of-apps-works/#appparams-injection). You need it when your app reads a value that comes from an AWS resource or the catalog's configuration (e.g. an S3 bucket name, a certificate ARN, or the region). For a value that only differs per environment, see [Configure an App per Environment](/docs/applications/configure-an-app-per-environment/) instead.

It's one of the [Extra Steps](/docs/applications/add-edit-or-remove-an-app/#extra-steps) of adding or editing an app, and assumes you've created a branch in both forks, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch).

For a hostname, see [Expose an App](/docs/applications/expose-an-app/). For a secret, see [Pass a Secret to an App](/docs/applications/pass-a-secret-to-an-app/).

## In Your App of Apps Fork

### Leave the Value Empty in the Chart

In your chart's `values.yaml`, set the value to empty, with a comment saying the catalog injects it. Pick the tab that fits your chart:
- **Own chart**: your templates read the value.
- **Upstream chart**: your chart wraps an upstream chart as a dependency, and the upstream chart reads the value.

<Tabs groupId="chart-type">
<TabItem value="own" label="Own chart">

Set the value at the top level. For example, the Tailscale connector's name, hostname prefix, and advertised routes, in [`charts/tailscale/connector/values.yaml`](../charts/tailscale/connector/values.yaml):
```yaml
# Injected per instance by the catalog (terragrunt-template-catalog-eks) via appParams,
# from the EKS cluster name and VPC CIDR. See units/eks/addons/argocd/app_of_apps in
# that repo. No instance sets this itself.
name: ""
hostnamePrefix: ""
advertiseRoutes: []
```

</TabItem>
<TabItem value="upstream" label="Upstream chart">

Nest the value under the dependency's `name` from your `Chart.yaml`. For example, the AWS Load Balancer Controller's cluster name, region, and VPC ID, under its `aws-load-balancer-controller` dependency, in [`charts/aws-lbc/values.yaml`](../charts/aws-lbc/values.yaml):
```yaml
aws-load-balancer-controller:
  # Injected by the catalog (terragrunt-template-catalog-eks) via appParams, from the EKS
  # cluster name, region, and VPC ID. See units/eks/addons/argocd/app_of_apps in that repo.
  clusterName: ""
  region: ""
  vpcId: ""
  ...
```

</TabItem>
</Tabs>

### Require the Value in the Chart Schema

In your chart's `values.schema.json`, list the value under `required`, and reject an empty one with `minLength: 1` for a string or `minItems: 1` for an array. A missing value then fails the render instead of deploying empty. If your chart has no schema yet, create one.

<Tabs groupId="chart-type">
<TabItem value="own" label="Own chart">

For example, [`charts/tailscale/connector/values.schema.json`](../charts/tailscale/connector/values.schema.json):
```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "title": "Values",
  "type": "object",
  "required": ["name", "hostnamePrefix", "advertiseRoutes"],
  "properties": {
    "name": { "type": "string", "minLength": 1 },
    "hostnamePrefix": { "type": "string", "minLength": 1 },
    "advertiseRoutes": { "type": "array", "minItems": 1, "items": { "type": "string" } }
  }
}
```

</TabItem>
<TabItem value="upstream" label="Upstream chart">

Require the dependency's key too, so the whole path to the value is required. For example, [`charts/aws-lbc/values.schema.json`](../charts/aws-lbc/values.schema.json):
```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "title": "Values",
  "type": "object",
  "required": ["vpcEndpointCidrs", "aws-load-balancer-controller"],
  "properties": {
    ...
    "aws-load-balancer-controller": {
      "type": "object",
      "required": ["clusterName", "region", "vpcId"],
      "properties": {
        "clusterName": { "type": "string", "minLength": 1 },
        "region": { "type": "string", "minLength": 1 },
        "vpcId": { "type": "string", "minLength": 1 }
      }
    }
  }
}
```

</TabItem>
</Tabs>

### Add Placeholder Values

Next to your chart's `values.yaml`, add a `placeholder-values.yaml` with a dummy value for each injected one, so CI can render the chart without the catalog (see [Placeholder Values](/docs/applications/how-the-app-of-apps-works/#placeholder-values)). Each dummy must pass your schema.

<Tabs groupId="chart-type">
<TabItem value="own" label="Own chart">

For example, [`charts/tailscale/connector/placeholder-values.yaml`](../charts/tailscale/connector/placeholder-values.yaml):
```yaml
# Used only by scripts/validate-helm.sh so standalone `helm template` and
# kubeconform pass. Real values are injected by the catalog
# (terragrunt-template-catalog-eks) via appParams, from the EKS cluster name
# and VPC CIDR. See units/eks/addons/argocd/app_of_apps in that repo.
name: "placeholder-connector"
hostnamePrefix: "placeholder"
advertiseRoutes:
  - "10.0.0.0/16"
```

</TabItem>
<TabItem value="upstream" label="Upstream chart">

Nest the dummies as in `values.yaml`. For example, [`charts/aws-lbc/placeholder-values.yaml`](../charts/aws-lbc/placeholder-values.yaml):
```yaml
# Used only by scripts/validate-helm.sh so standalone `helm template` and
# kubeconform pass. Real values are injected by the catalog
# (terragrunt-template-catalog-eks) via appParams, from the EKS cluster name, region, and
# VPC ID. See units/eks/addons/argocd/app_of_apps in that repo.
...
aws-load-balancer-controller:
  clusterName: "placeholder-cluster"
  region: "us-east-1"
  vpcId: "vpc-placeholder"
```

</TabItem>
</Tabs>

### Allow the Key in the Apps Chart

If your app has no `appParams` key yet, add one under `appParams` in [`apps/values.schema.json`](../apps/values.schema.json), which rejects any key it doesn't list (see [`appParams` Injection](/docs/applications/how-the-app-of-apps-works/#appparams-injection)). Name it after the app's `name` in [`apps/values.yaml`](../apps/values.yaml), not its `path`. For example, for the Tailscale connector and the AWS Load Balancer Controller:
```json
"appParams": {
  "type": "object",
  "additionalProperties": false,
  "properties": {
    ...
    "aws-lbc": { "type": "object" },
    ...
    "tailscale-connector": { "type": "object" },
    ...
  }
}
```

Then add your placeholders under your app's key in [`apps/placeholder-values.yaml`](../apps/placeholder-values.yaml).

<Tabs groupId="chart-type">
<TabItem value="own" label="Own chart">

```yaml
appParams:
  ...
  tailscale-connector:
    name: "placeholder-connector"
    hostnamePrefix: "placeholder-cluster"
    advertiseRoutes: ["10.0.0.0/16"]
```

</TabItem>
<TabItem value="upstream" label="Upstream chart">

```yaml
appParams:
  ...
  aws-lbc:
    ...
    aws-load-balancer-controller:
      clusterName: "placeholder-cluster"
      region: "us-east-1"
      vpcId: "vpc-placeholder"
```

</TabItem>
</Tabs>

## In Your Catalog Fork

### Read the Value

Open the `argocd_app_of_apps` unit, [`units/eks/addons/argocd/app_of_apps/terragrunt.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl). Depending on where the value comes from:
- **Shared configuration** (e.g. the region): find the file that holds it in the [HCL Configuration](/docs/reference/hcl_configuration/) reference, and read it as in [Read Shared Config](/docs/iac/add-a-unit/#read-shared-config).
- **An output of a unit the file already reads outputs from** (e.g. `vpc`): skip to [Add the `appParams` Entry](#add-the-appparams-entry).
- **An output of any other unit**: read it as in [Read Other Units' Outputs](/docs/iac/add-a-unit/#read-other-units-outputs).
- **A resource no unit creates yet**: add it first by following [Add a Unit](/docs/iac/add-a-unit/), then come back.

### Add the `appParams` Entry

Under `inputs.helm_values.appParams`, add your app's key, with the same nesting as its placeholders. The app receives it as its Helm values (see [`appParams` Injection](/docs/applications/how-the-app-of-apps-works/#appparams-injection)).

<Tabs groupId="chart-type">
<TabItem value="own" label="Own chart">

```hcl
appParams = {
  ...
  "tailscale-connector" = {
    name            = "${dependency.eks_cluster.outputs.cluster_name}-connector"
    hostnamePrefix  = dependency.eks_cluster.outputs.cluster_name
    advertiseRoutes = [dependency.vpc.outputs.vpc_cidr_block]
  }
}
```

</TabItem>
<TabItem value="upstream" label="Upstream chart">

```hcl
appParams = {
  ...
  "aws-lbc" = {
    ...
    "aws-load-balancer-controller" = {
      clusterName = dependency.eks_cluster.outputs.cluster_name
      region      = local.region
      vpcId       = dependency.vpc.outputs.vpc_id
    }
  }
}
```

</TabItem>
</Tabs>

Then continue at [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev).
