{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}
# Deploy an App Change to Dev

Now that you've [forked](/docs/applications/get-started/app-of-apps-setup/#fork-the-app-of-apps-repository) the app of apps repository and [pointed your catalog at it](/docs/applications/get-started/app-of-apps-setup/#point-the-catalog-at-your-fork), you'll deploy the EKS stack in the [`dev` environment](/docs/iac/#dev), push a change to [podinfo](https://github.com/stefanprodan/podinfo), and watch ArgoCD sync it to your cluster.

## Create a Branch
From the root of your app of apps fork, create a branch and push it:
```bash
git checkout -b podinfo-message
git push -u origin podinfo-message
```

Then, in the `.env` of your catalog fork, set [`APP_OF_APPS_BRANCH`](/docs/reference/environment_variable/#app_of_apps_branch) to your branch so ArgoCD syncs from it instead of `main`:
```bash
export APP_OF_APPS_BRANCH=podinfo-message
```

## Deploy the Dev Stack
Deploy the `dev` environment by following the [Run the Terragrunt Stack](/docs/quickstart/deployment/#run-the-terragrunt-stack) and [Deploy Applications with ArgoCD](/docs/quickstart/deployment/#deploy-applications-with-argocd) steps of the dev deployment. This time, ArgoCD syncs the applications from your branch.

## Log In to ArgoCD
Connect to Tailscale and open the ArgoCD UI in your browser, as in the [Log In to ArgoCD](/docs/quickstart/deployment/#log-in-to-argocd) step of the dev deployment.

## Explore the App of Apps
The home page shows one tile per ArgoCD [Application](https://argo-cd.readthedocs.io/en/stable/core_concepts/). Type `app-of-apps` in the search bar to find its tile.

Click on it. The tree shows every other Application downstream of `app-of-apps`. Each one is an entry under `applications` in [`apps/values.yaml`](../apps/values.yaml) of your fork. Open this file and find the `podinfo` entry:
```yaml
  - name: podinfo
    path: manifests/podinfo
    destination:
      namespace: podinfo
    syncWave: 4
```
Its `path` points at the directory ArgoCD deploys this Application from.

Back in the UI, click **Details** at the top of `app-of-apps`. Notice the **REPO URL** is your fork and the **TARGET REVISION** is your branch, `refs/heads/podinfo-message`.

Go back to the home page, type `podinfo` in the search bar, and click on its tile. The tree shows the Kubernetes resources of this Application, such as its Pods and Service. Notice they match the files in [`manifests/podinfo/`](../manifests/podinfo/).

At the top of the page, two statuses summarize the Application:
- **APP HEALTH**: whether its resources are running. `Healthy` means they are.
- **SYNC STATUS**: whether the cluster matches git. `Synced` means it does. Below it, ArgoCD shows the branch and commit SHA it synced to, with the commit's author and message.

Click on `to refs/heads/podinfo-message (<commit-sha>)` under **SYNC STATUS**. It opens the exact commit ArgoCD deployed on GitHub.

## Check Podinfo
Open `https://podinfo.public.dev.<base_domain>` in your browser (replace `<base_domain>` with the [value from `pipelines/dns.hcl`](/docs/quickstart/bootstrap/setup_dns/)). You should see the default `greetings from podinfo v6.14.1` message.

## Change Podinfo
From the root of your app of apps fork, open [`manifests/podinfo/podinfo-deployment.yaml`](../manifests/podinfo/podinfo-deployment.yaml) and add an `env` field to the `podinfo` container:
```yaml
      containers:
        - image: ghcr.io/stefanprodan/podinfo:6.14.1
          name: podinfo
          env:
            - name: PODINFO_UI_MESSAGE
              value: "greetings from my fork"
          ...
```

Commit your change and push it to your branch:
```bash
git commit -am "feat(podinfo): change ui message"
git push
```

## Watch ArgoCD Sync
ArgoCD checks your branch for new commits every few minutes. Instead of waiting, you'll sync manually with the `argocd` CLI.

From the root of your catalog fork, where mise installs `argocd`, log in with the CLI as in the [Log In to ArgoCD](/docs/quickstart/deployment/#log-in-to-argocd) step of the dev deployment.

Then, sync every Application of the `default` project:
```bash
argocd app sync --project default
```

This syncs all Applications at once, so you never miss one that changed.

Back in the UI, open the `podinfo` Application. **SYNC STATUS** now shows your commit SHA and your `feat(podinfo): change ui message` message. In the tree, a new Pod replaces the old one.

Reload `https://podinfo.public.dev.<base_domain>`. You should see `greetings from my fork`.

Notice you didn't run Terragrunt. ArgoCD applied your change from git.

## Change the Cluster by Hand
Now, change the message directly in the cluster, without git:
```bash
kubectl set env deployment/podinfo PODINFO_UI_MESSAGE="changed by hand" -n podinfo
```

Watch the `podinfo` Application in the UI. ArgoCD detects that the cluster no longer matches git and reverts your change. Reload podinfo: it shows `greetings from my fork` again.

Git is the source of truth. To change an application, commit to your app of apps fork instead of editing the cluster.

## Destroy the Infrastructure
Destroy the `dev` environment by following the [Destroy the Infrastructure](/docs/quickstart/deployment/#destroy-the-infrastructure) step of the dev deployment.

Finally, remove the `APP_OF_APPS_BRANCH` line from the `.env` of your catalog fork, so your next `dev` deployment syncs from `main` again.

## What's Next
Learn [how to add, edit, or remove an app](/docs/applications/add-edit-or-remove-an-app/) in your fork, then test it in `dev` the same way.
