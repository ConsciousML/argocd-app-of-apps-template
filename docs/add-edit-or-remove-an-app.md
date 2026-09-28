{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}

# Add, Edit, or Remove an App

This guide shows you how to add, edit, or remove an [application](/docs/applications/how-the-app-of-apps-works/#the-root-app-and-its-children) in your [app of apps fork](/docs/applications/get-started/app-of-apps-setup/#fork-the-app-of-apps-repository), test it in [`dev`](/docs/iac/#dev), and merge it. It assumes you've already [pointed your catalog at your fork](/docs/applications/get-started/app-of-apps-setup/#point-the-catalog-at-your-fork).

To ship a merged change to `staging` and `prod`, see [Release an App Change](/docs/applications/release-an-app-change/) instead.

## Point Dev at Your Branch

From the root of your app of apps fork, create a branch and push it, replacing `<branch>`:
```bash
git checkout -b <branch>
git push -u origin <branch>
```

If your change also touches your catalog fork, because your app needs a value from Terraform, a secret, a hostname, or an AWS resource, or you remove an app that receives Terraform values, create a branch from the root of your catalog fork too. Units fetch the catalog's modules from git at your current branch, so the apply below fails until the branch exists on your fork:
```bash
git checkout -b <branch>
git push -u origin <branch>
```

Then, in the `.env` of your catalog fork, set [`APP_OF_APPS_BRANCH`](/docs/reference/environment_variable/#app_of_apps_branch) to your branch, so ArgoCD syncs `dev` from it instead of `main`:
```bash
export APP_OF_APPS_BRANCH=<branch>
```

The catalog reads `APP_OF_APPS_BRANCH` only when it applies the root Application. If `dev` isn't deployed yet, deploy it as in [Deploy the Dev Stack](/docs/applications/get-started/deployment/#deploy-the-dev-stack). If it's already running, re-apply only the `argocd_app_of_apps` unit from the root of your catalog fork:
```bash
source .env
cd pipelines/dev/eks/stack
terragrunt stack clean
terragrunt stack generate
cd .terragrunt-stack/eks/addons/argocd/app_of_apps
terragrunt apply
```

For a guided walkthrough of this loop, see [Deploy an App Change to Dev](/docs/applications/get-started/deployment/).

## Add an App

### Create the Namespace

If your app will run in a new namespace, add it to [`manifests/namespaces/`](../manifests/namespaces/). Otherwise, its sync fails, since [no Application can create its own namespace](/docs/applications/how-the-app-of-apps-works/#namespaces).

Label it with a [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/) level. By default, enforce `baseline`, like [`manifests/namespaces/podinfo.yaml`](../manifests/namespaces/podinfo.yaml):
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: podinfo
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/audit: restricted
```

If your pods break a [`baseline` rule](https://kubernetes.io/docs/concepts/security/pod-security-standards/#baseline), enforce `privileged` instead. Add a comment naming what needs it, like [`manifests/namespaces/monitoring.yaml`](../manifests/namespaces/monitoring.yaml):
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
  labels:
    # kube-prometheus-stack's prometheus-node-exporter needs hostNetwork, hostPID, and a
    # hostPath rootfs mount to collect host metrics, baseline would reject it.
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/warn: privileged
    pod-security.kubernetes.io/audit: privileged
```

### Write the App

Put the app's files in a new directory, as either:
- **Plain manifests** under `manifests/<name>/`, one [Kubernetes manifest](https://kubernetes.io/docs/concepts/overview/working-with-objects/) per resource (e.g. [`manifests/podinfo`](../manifests/podinfo/)).
- **A Helm chart** under `charts/<chart>/` or `charts/<group>/<chart>/`, [written](https://helm.sh/docs/topics/charts/) from scratch or wrapping an upstream chart as a dependency (e.g. [`charts/monitoring/blackbox-exporter`](../charts/monitoring/blackbox-exporter/)).

Add a `nodeSelector` and `tolerations` to the app's pods by following [How to Schedule Pods](/docs/compute/schedule-pods/).

### Add Placeholder Values

If your chart reads a value passed from Terraform, leave it empty in its `values.yaml`, with a comment saying where it comes from. Then add a `placeholder-values.yaml` next to it with a dummy value, so CI can render the chart (see [Placeholder Values](/docs/applications/how-the-app-of-apps-works/#placeholder-values)). For example, the `host` of [`charts/gateway-api/httproute`](../charts/gateway-api/httproute/):
```yaml
# values.yaml
# Injected per instance by the catalog via appParams.
host: ""
```

```yaml
# placeholder-values.yaml
host: "placeholder"
```

### Declare the Application

Add an entry under `applications` in [`apps/values.yaml`](../apps/values.yaml), with the app's `name`, the `path` of its files, its `destination.namespace`, and its `syncWave` (see [Set the Sync Wave](#set-the-sync-wave)). For example, podinfo's entry:
```yaml
  - name: podinfo
    path: manifests/podinfo
    destination:
      namespace: podinfo
    syncWave: 4
```

For the other fields, such as `tool.helm.releaseName` or `syncOptions`, see the [App of Apps reference](/docs/reference/applications/app_of_apps/).

### Set the Sync Wave

The `syncWave` sets when ArgoCD [syncs the app](/docs/applications/how-the-app-of-apps-works/#sync-waves), relative to the other entries. List the entries your app needs running before it starts in a `# Depends on:` comment above its entry, then set its `syncWave` to the highest `syncWave` among them, plus one.

Take into account these implicit dependencies when computing it:
- **`network-policies-cluster-wide`**, at wave `3`.
- **The DaemonSets**: if your app runs pods, at wave `3` or later (see [DaemonSets Priority](/docs/applications/how-the-app-of-apps-works/#daemonsets-priority)).

For example, podinfo only depends on `network-policies-cluster-wide`, at wave `3`, so its `syncWave` is `3 + 1 = 4`:
```yaml
  # Depends on:
  # - network-policies-cluster-wide
  - name: podinfo
    ...
    syncWave: 4
```

If your app deploys no workload, only resources others need, such as CRDs, and depends on no other entry, set its `syncWave` to `-1`.

### Extra Steps

Depending on what your app needs, also follow:
- **A value from Terraform** (e.g. a bucket name or a certificate ARN): [How to Pass Terraform Values to an App](/docs/applications/pass-terraform-values-to-an-app/).
- **A secret** (e.g. a password): [How to Pass a Secret to an App](/docs/applications/pass-a-secret-to-an-app/).
- **A hostname**: [How to Expose an App](/docs/applications/expose-an-app/).
- **A different config per environment**: [How to Configure an App per Environment](/docs/applications/configure-an-app-per-environment/).
- **An AWS resource** (e.g. an S3 bucket or an IAM role): [How to Add, Edit, or Remove a Unit](/docs/iac/add-a-unit/).

## Edit an App

Change the app's files, or its entry in [`apps/values.yaml`](../apps/values.yaml). For a change that needs one of the [Extra Steps](#extra-steps), follow its guide. If you add a value passed from Terraform, give it a placeholder too, as in [Add Placeholder Values](#add-placeholder-values).

If the app's dependencies change, update its `# Depends on:` comment and [recompute its `syncWave`](#set-the-sync-wave). Then recompute the `syncWave` of every entry that depends on it, since a shifted wave cascades downstream.

## Remove an App

Delete:
- The app's directory under `manifests/` or `charts/`. Skip it if another entry shares it (e.g. `charts/gateway-api/httproute`), and delete only the app's own values file instead.
- The app's entry in [`apps/values.yaml`](../apps/values.yaml). Drop it from the `# Depends on:` comment of every entry that listed it, and [recompute their `syncWave`](#set-the-sync-wave).
- The app's namespace from [`manifests/namespaces/`](../manifests/namespaces/) and [`manifests/network-policies/cluster-wide/`](../manifests/network-policies/cluster-wide/), if no other app runs in it.
- The app's key in [`apps/values.schema.json`](../apps/values.schema.json) and under `appParams` in [`apps/placeholder-values.yaml`](../apps/placeholder-values.yaml), if it receives [Terraform values](/docs/applications/pass-terraform-values-to-an-app/). Also delete its entry under `appParams` in the catalog's [`argocd_app_of_apps` unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/addons/argocd/app_of_apps/terragrunt.hcl), and merge that catalog change first (see [Merge](#merge)).
- Any other reference to the app in the catalog's `argocd_app_of_apps` unit, such as its hostname in `locals` or its target under the `blackbox-exporter` entry of `appParams`.

Once ArgoCD syncs the removal, it deletes the app's resources, but [never its namespace](/docs/applications/how-the-app-of-apps-works/#deletion-safety). If you deleted the namespace's file, delete the namespace by hand in each environment the removal reaches. This also deletes what's left inside it, such as the volumes of a `StatefulSet`:
```bash
kubectl delete namespace <namespace>
```

## Test in Dev

From the root of your app of apps fork, commit your change and push it to the branch `dev` syncs from, replacing `<message>`:
```bash
git add -A
git commit -m "<message>" # e.g. "feat: add my-app"
git push
```

If you also changed your catalog fork, commit your change on its branch and push it, since units fetch the catalog's modules from git. Then redeploy the `dev` stack as in [Deploy the Dev Stack](/docs/applications/get-started/deployment/#deploy-the-dev-stack), so every unit you added or changed is applied.

From the root of your catalog fork, log in with the `argocd` CLI as in the [Log In to ArgoCD](/docs/quickstart/deployment/#log-in-to-argocd) step of the dev deployment, then sync every Application:
```bash
argocd app sync --project default
```

Check that your app's Application is `Healthy` and `Synced`, and that its pods are running:
```bash
argocd app get <app>
kubectl get pods -n <namespace>
```

This only shows the app started. Then, test that it behaves as intended (e.g. by calling its `Service` through [`kubectl port-forward`](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)).

:::warning
A [network policy](https://docs.cilium.io/en/stable/security/policy/) can silently drop the traffic between your app and an existing component. If your app's logs show connection timeouts, or its Application is stuck in the `Degraded` state, list the traffic dropped in the cluster from the root of your catalog fork:
```bash
hubble observe --verdict DROPPED -P | grep -v "Unsupported L3"
```

If it shows drops to or from your app, see [How to Control an App's Network Traffic](/docs/security/control-an-app-network-traffic/).
:::

## Restrict the App's Traffic

If you added an app in a new namespace, its traffic isn't restricted yet. Deny all its traffic by default, then allow only what it needs, by following [How to Control an App's Network Traffic](/docs/security/control-an-app-network-traffic/). Then [test it in dev](#test-in-dev) again.

## Open a Pull Request

From the root of your app of apps fork, open a pull request, replacing `<title>` and `<description>`:
```bash
gh pr create --title "<title>" --body "<description>"
```

Make sure CI passes. If it fails, see [Troubleshoot App of Apps CI](/docs/ci-cd/per-repository/troubleshoot-app-of-apps-ci/).

If you also changed your catalog fork, open a pull request there too, and make sure its CI passes. If it fails, see [Troubleshoot Catalog CI](/docs/ci-cd/per-repository/troubleshoot-catalog-ci/).

## Merge

When every job is green, merge from the root of your app of apps fork:
```bash
gh pr merge --merge
```

If you also opened a pull request in your catalog fork, merge it the same way from its root, in this order, since [`apps/values.schema.json`](../apps/values.schema.json) rejects any `appParams` key it doesn't list:
- **You added an `appParams` key**: merge the app of apps pull request first, then the catalog one.
- **You removed an `appParams` key**: merge the catalog pull request first, then the app of apps one.

Finally, remove the `APP_OF_APPS_BRANCH` line from the `.env` of your catalog fork, so your next `dev` deployment syncs from `main` again.

To ship your change to `staging` and `prod`, see [Release an App Change](/docs/applications/release-an-app-change/).
