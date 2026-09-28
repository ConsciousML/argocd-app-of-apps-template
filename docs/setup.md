{/* This doc is aggregated into the EKS Forge documentation site: https://eks-forge.readthedocs.io/latest/. It is not meant to be read directly in this repository. */}
# ArgoCD App of Apps Setup

In this tutorial, you'll fork the [ArgoCD app of apps repository](https://github.com/ConsciousML/argocd-app-of-apps-template) and point your catalog fork at it to deploy your own applications to your cluster.

## Fork the App of Apps Repository
The app of apps repository holds the [Helm charts](https://helm.sh/docs/topics/charts/) and manifests that [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) syncs into your cluster. Like the catalog and live repositories, it's meant to be forked and extended.

First, [create an empty repository](https://github.com/new) on GitHub. Make it public, since ArgoCD reads it without credentials. Leave the README, `.gitignore`, and license options unset.

Then, set your GitHub owner (user or organization) and the name of the repository you created, by replacing the `<...>`:
```bash
export GITHUB_OWNER=<your-github-owner>
export APP_OF_APPS_REPO_NAME=<your-app-of-apps-repo-name>
```

Clone the app of apps repository and push it to your repository:
```bash
git clone https://github.com/ConsciousML/argocd-app-of-apps-template.git $APP_OF_APPS_REPO_NAME
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

## Point the Catalog at Your Fork
From the root of your [catalog fork](/docs/quickstart/installation/#fork-the-eks-forge-catalog), set these two values in [`pipelines/github.hcl`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/pipelines/github.hcl) and leave the others as is:
```hcl
locals {
  github_owner_app_of_apps     = "<your-github-username-or-org-name-where-your-app-of-apps-fork-is>"
  github_repo_name_app_of_apps = "<your-app-of-apps-repo-name>"
  ...
}
```
On your next `dev` deployment, ArgoCD syncs every application from your fork instead of the original app of apps repository.
