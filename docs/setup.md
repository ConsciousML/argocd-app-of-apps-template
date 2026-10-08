{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}
# ArgoCD App of Apps Setup

In this tutorial, you'll fork the [ArgoCD app of apps repository](https://github.com/ConsciousML/eks-forge-app-of-apps), set up its pre-commit hooks, and point your catalog fork at it to deploy your own applications to your cluster.

## Fork the App of Apps Repository
The app of apps repository holds the [Helm charts](https://helm.sh/docs/topics/charts/) and manifests that [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) syncs into your cluster. Like the catalog and live repositories, it's meant to be forked and extended.

First, create an empty repository from [GitHub's new repository page](https://github.com/new). Make it public, since ArgoCD reads it without credentials. Leave the README, `.gitignore`, and license options unset.

Then, set your GitHub owner (user or organization) and the name of the repository you created, by replacing the `<...>`:
```bash
export GITHUB_OWNER=<your-github-owner>
export APP_OF_APPS_REPO_NAME=<your-app-of-apps-repo-name>
```

Clone the app of apps repository and push it to your repository:
```bash
git clone https://github.com/ConsciousML/eks-forge-app-of-apps.git $APP_OF_APPS_REPO_NAME
cd $APP_OF_APPS_REPO_NAME
git remote set-url origin git@github.com:$GITHUB_OWNER/$APP_OF_APPS_REPO_NAME.git
git push origin main
git push origin --tags
```

:::warning
Follow these exact steps instead of GitHub's `Fork` or `Use this template` buttons, so your repository gets the [version tags](/docs/applications/how-the-app-of-apps-works/#versioning-per-environment).
:::

## Install the CLI Tools
From the root of your app of apps fork, install the tools pinned in [`mise.toml`](../mise.toml):
```bash
mise trust
mise install
```

## Enable the Pre-commit Hooks
Your fork comes with [prek](https://github.com/j178/prek) hooks, defined in [`prek.toml`](../prek.toml). They lint the Helm charts, validate the manifests against their Kubernetes schemas, and scan them with [Trivy](https://trivy.dev/). These are the same checks the CI runs on every pull request, so you'll catch issues before you push.

`mise` already installed `prek`. Wire the hooks into git:
```bash
prek install
```

The Helm hook builds the dependencies of each chart, so register the chart repositories they come from:
```bash
scripts/helm-repo-add.sh
```

Run every hook against the whole repository:
```bash
prek run --all-files
```

You'll see each hook pass:
```
Helm lint and kubeconform................................................Passed
kubeconform plain manifests..............................................Passed
Trivy....................................................................Passed
Trivy secret scan........................................................Passed
```

From now on, the hooks run on the files you change each time you `git commit`.

## Point the Catalog at Your Fork
From the root of your [catalog fork](/docs/quickstart/installation/#fork-the-eks-forge-catalog), set these two values in [`pipelines/github.hcl`](https://github.com/ConsciousML/eks-forge-catalog/blob/main/pipelines/github.hcl) and leave the others as is:
```hcl
locals {
  github_owner_app_of_apps     = "<your-github-username-or-org-name-where-your-app-of-apps-fork-is>"
  github_repo_name_app_of_apps = "<your-app-of-apps-repo-name>"
  ...
}
```
On your next `dev` deployment, ArgoCD syncs every application from your fork instead of the original app of apps repository.

## Enable README Generation in CI
Your fork's CI generates each chart's README and pushes it back to your PR. To push, it needs a write deploy key, stored as the `HELM_DOCS_DEPLOY_KEY` secret on your fork.

The `app_of_apps_deploy_key` [bootstrap pipeline](/docs/quickstart/bootstrap) creates both. It reads your fork's owner and name from the `github.hcl` you just edited.

From the root of your [catalog fork](/docs/quickstart/installation/#fork-the-eks-forge-catalog), run:
```bash
source .env
cd pipelines/bootstrap/app_of_apps_deploy_key/
terragrunt stack clean
terragrunt stack generate
terragrunt run --all apply --backend-bootstrap --non-interactive --no-stack-generate
```

Then, list the GitHub Actions secrets of your app of apps fork:
```bash
gh secret list -R $GITHUB_OWNER/$APP_OF_APPS_REPO_NAME
```

You should see `HELM_DOCS_DEPLOY_KEY`.

Finally, list the deploy keys of your app of apps fork:
```bash
gh repo deploy-key list -R $GITHUB_OWNER/$APP_OF_APPS_REPO_NAME
```

You should see `Helm Docs Deploy Key` with `read-write` permission.

For more information about this bootstrap, read the [App of Apps Deploy Key](/docs/reference/bootstrap/app_of_apps_deploy_key/) reference.
