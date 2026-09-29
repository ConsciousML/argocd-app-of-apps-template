{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# How to Pass a Secret to an App

This guide shows you how to create a secret in [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) and have the [External Secrets Operator](https://external-secrets.io/latest/) (ESO) sync it into a [Kubernetes `Secret`](https://kubernetes.io/docs/concepts/configuration/secret/) your app reads. You need it when your app reads a sensitive value (e.g. a password or an API token). It's one of the [Extra Steps](/docs/applications/add-edit-or-remove-an-app/#extra-steps) of adding or editing an app, and assumes you've created a branch in both forks, as in [Point Dev at Your Branch](/docs/applications/add-edit-or-remove-an-app/#point-dev-at-your-branch).

For a value that isn't sensitive, see [Pass Terraform Values to an App](/docs/applications/pass-terraform-values-to-an-app/) instead.

## In Your App of Apps Fork

### Add a Secret Values File

The [`secret-sync`](../charts/external-secrets-operator/secret-sync/) chart copies keys from one AWS secret into one Kubernetes `Secret`. Next to its `values.yaml`, add a `<app>-secrets-values.yaml` that sets all of:
- `name`: the name of the [`ExternalSecret`](https://external-secrets.io/latest/api/externalsecret/), the resource telling ESO what to copy.
- `targetSecretName`: the name of the Kubernetes `Secret` ESO writes to, the one your app reads.
- `targetCreationPolicy`: how ESO creates that `Secret`, usually `Owner`. See ESO's [Creation Policy](https://external-secrets.io/latest/guides/ownership-deletion-policy/#creation-policy).
- `refreshPolicy`: when ESO syncs the value again, `CreatedOnce` for a value that never changes, or `Periodic` if it can be rotated. See ESO's [Refresh Policy](https://external-secrets.io/latest/guides/ownership-deletion-policy/#refresh-policy).
- `data`: one entry per key to copy, with `remoteProperty` the key in the AWS secret (`plaintext` or `bcrypt_hash` for a generated password, otherwise a key you set in `secret_data`, see [Create the Secret](#create-the-secret)), and `secretKey` its key in the Kubernetes `Secret`.

For example, Grafana's admin password, in [`grafana-secrets-values.yaml`](../charts/external-secrets-operator/secret-sync/grafana-secrets-values.yaml):
```yaml
name: grafana-admin-password
targetSecretName: grafana-admin-credentials
targetCreationPolicy: Owner
refreshPolicy: CreatedOnce
data:
  - secretKey: admin-password
    remoteProperty: plaintext
```

### Declare the Secret Entry

Add a `<app>-secrets` entry under `applications` in [`apps/values.yaml`](../apps/values.yaml), with:
- `path`: the `secret-sync` chart.
- `destination.namespace`: your app's namespace.
- `syncWave`: `5`, since it depends on `external-secrets-operator`, at wave `4` (see [Set the Sync Wave](/docs/applications/add-edit-or-remove-an-app/#set-the-sync-wave)).
- `extraValueFiles`: your secret values file.

For example, Grafana's entry:
```yaml
  # Depends on:
  # - external-secrets-operator
  - name: grafana-secrets
    path: charts/external-secrets-operator/secret-sync
    destination:
      namespace: monitoring
    syncWave: 5
    extraValueFiles:
      - charts/external-secrets-operator/secret-sync/grafana-secrets-values.yaml
```

### Allow the Key in the Apps Chart

The catalog injects the rest of the `secret-sync` values, `secretStoreName`, `awsRegion`, and `remoteKey`, through [`appParams`](/docs/applications/how-the-app-of-apps-works/#appparams-injection). Allow your `<app>-secrets` key and add its placeholders to the apps chart, by following [Allow the Key in the Apps Chart](/docs/applications/pass-terraform-values-to-an-app/#allow-the-key-in-the-apps-chart) and [Add Placeholders to the Apps Chart](/docs/applications/pass-terraform-values-to-an-app/#add-placeholders-to-the-apps-chart). For example, Grafana's placeholders in [`apps/placeholder-values.yaml`](../apps/placeholder-values.yaml):
```yaml
appParams:
  ...
  grafana-secrets:
    secretStoreName: "placeholder-store"
    awsRegion: "us-east-1"
    remoteKey: "placeholder-key"
```

### Read the Secret in Your App

Your app's chart reads the `Secret` through its own values (often named `existingSecret`). Set them in your [secret values file](#add-a-secret-values-file), so the `Secret`'s name and key are written only once:
- Mark `targetSecretName` and `secretKey` with a [YAML anchor](https://yaml.org/spec/1.2.2/#692-node-anchors) (`&<anchor>`).
- At the end of the file, add your app's values, pointing at the anchors with aliases (`*<anchor>`). The `secret-sync` chart ignores them.

For example, `kube-prometheus-stack` reads Grafana's admin password from `grafana.admin.existingSecret` and `grafana.admin.passwordKey`, in [`grafana-secrets-values.yaml`](../charts/external-secrets-operator/secret-sync/grafana-secrets-values.yaml):
```yaml
...
targetSecretName: &secretName grafana-admin-credentials
...
data:
  - secretKey: &secretKey admin-password
    remoteProperty: plaintext

kube-prometheus-stack:
  grafana:
    admin:
      existingSecret: *secretName
      passwordKey: *secretKey
```

Then add your secret values file to your app's `extraValueFiles` in [`apps/values.yaml`](../apps/values.yaml), so your app reads these values too. For example, `kube-prometheus-stack`'s entry:
```yaml
  - name: kube-prometheus-stack
    ...
    extraValueFiles:
      - charts/external-secrets-operator/secret-sync/grafana-secrets-values.yaml
```

If your app needs the `Secret` before it starts (e.g. to set a password on first boot), add `<app>-secrets` to its `# Depends on:` comment in [`apps/values.yaml`](../apps/values.yaml), and recompute its `syncWave` (see [Set the Sync Wave](/docs/applications/add-edit-or-remove-an-app/#set-the-sync-wave)). For example, `kube-prometheus-stack` runs after `grafana-secrets` (wave `5`), at wave `6`:
```yaml
  # Depends on:
  # - grafana-secrets (needs the admin secret before Grafana's first boot)
  # ...
  - name: kube-prometheus-stack
    ...
    syncWave: 6
```

## In Your Catalog Fork

### Create the Secret

Create a unit that stores your secret in AWS Secrets Manager, by following the **Custom module** tab of [Write the Unit](/docs/iac/add-a-unit/#write-the-unit), skipping the module since it already exists. Pick the tab that fits your secret:
- **Generated password**: the catalog generates it for you.
- **Other value**: you pass the value, from the stack or from another unit's outputs.

<Tabs groupId="secret-source">
<TabItem value="generated" label="Generated password">

Use the [`aws_secret_password`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/modules/aws_secret_password) module. It stores the password under the `plaintext` key, and its bcrypt hash under `bcrypt_hash`. For example, Grafana's unit, [`units/eks/addons/prometheus_stack/grafana/aws_secret_password/terragrunt.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/prometheus_stack/grafana/aws_secret_password/terragrunt.hcl):
```hcl
terraform {
  source = "git::git@github.com:${include.root.locals.github_owner_catalog}/${include.root.locals.github_repo_name_catalog}.git//modules/aws_secret_password/?ref=${values.version}"
}

inputs = {
  secret_name             = "${include.root.locals.environment}-grafana-password"
  length                  = values.length
  recovery_window_in_days = values.recovery_window_in_days
  tags                    = values.tags
}
```

</TabItem>
<TabItem value="other" label="Other value">

Use the [`aws_secretsmanager_secret`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/modules/aws_secretsmanager_secret) module. It stores each key you set in `secret_data`, which your `remoteProperty` values must match. For example, the Slack bot token Alertmanager reads, in [`units/eks/addons/prometheus_stack/alertmanager/aws_secret_slack_bot/terragrunt.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/prometheus_stack/alertmanager/aws_secret_slack_bot/terragrunt.hcl):
```hcl
terraform {
  source = "git::git@github.com:${include.root.locals.github_owner_catalog}/${include.root.locals.github_repo_name_catalog}.git//modules/aws_secretsmanager_secret/?ref=${values.version}"
}

inputs = {
  name = "${include.root.locals.environment}-alertmanager-slack-bot"
  secret_data = {
    bot_token = values.bot_token
  }
  recovery_window_in_days = values.recovery_window_in_days
  tags                    = values.tags
}
```

The dev stack passes it `bot_token` from an environment variable, with `bot_token = get_env("SLACK_BOT_TOKEN")`. To read a value from another unit's outputs instead, see [Read Other Units' Outputs](/docs/iac/add-a-unit/#read-other-units-outputs).

</TabItem>
</Tabs>

:::warning
Prefix the secret's name with `${include.root.locals.environment}-`, as in [Read Shared Config](/docs/iac/add-a-unit/#read-shared-config). ESO's [IAM role](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/external_secrets_operator/iam_role/terragrunt.hcl) can only read secrets whose name starts with the environment, so any other name fails the sync.
:::

Then:
1. Write its README with [Document the Unit](/docs/iac/add-a-unit/#document-the-unit).
2. Add it to the dev stack, as shown in [Add the Unit to the Dev Stack](/docs/iac/add-a-unit/#add-the-unit-to-the-dev-stack).

### Pass the Secret to ESO

In the `argocd_app_of_apps` unit, [`units/eks/addons/argocd/app_of_apps/terragrunt.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl), read your unit's `secret_name` output, as in [Read Other Units' Outputs](/docs/iac/add-a-unit/#read-other-units-outputs). For example, for Grafana:
```hcl
dependency "grafana_password" {
  config_path = "../../prometheus_stack/grafana/aws_secret_password"
  mock_outputs = {
    secret_name = "mock-grafana-password"
  }
  mock_outputs_allowed_terraform_commands = ["init", "plan", "validate", "graph", "destroy"]
}
```

Then, under `inputs.helm_values.appParams`, add your `<app>-secrets` key (see [Add the `appParams` Entry](/docs/applications/pass-terraform-values-to-an-app/#add-the-appparams-entry)), with:
- `secretStoreName`: `"${include.root.locals.environment}-aws-secrets-manager-<app>"`, the name of the [`SecretStore`](https://external-secrets.io/latest/api/secretstore/) the chart creates, which tells ESO how to reach AWS Secrets Manager from your app's namespace.
- `awsRegion`: `include.root.locals.aws_region`.
- `remoteKey`: your unit's `secret_name` output.

For example, for Grafana:
```hcl
appParams = {
  ...
  "grafana-secrets" = {
    secretStoreName = "${include.root.locals.environment}-aws-secrets-manager-grafana"
    awsRegion       = include.root.locals.aws_region
    remoteKey       = dependency.grafana_password.outputs.secret_name
  }
}
```

Then follow [Test in Dev](/docs/applications/add-edit-or-remove-an-app/#test-in-dev). After you sync, also check that ESO copied your secret, replacing `<namespace>` with your app's namespace. Its `STATUS` must be `SecretSynced`:
```bash
kubectl get externalsecret -n <namespace>
```
