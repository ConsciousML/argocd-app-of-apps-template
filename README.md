# ArgoCD App of Apps Template 

An ArgoCD template repository implementing the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative) with CI checks.

## Prerequisites
- A functional ArgoCD instance
- ArgoCD CRDs must be installed in your cluster
- The `argocd` namespace must exist in your cluster
- Knowledge of the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative)
- [Gateway API CRDs v1.5](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.5.0) and a shared [`Gateway`](https://gateway-api.sigs.k8s.io/reference/api-types/gateway/) resource provisioned in the cluster (for `guestbook-httproute`)

## Getting Started

1. Click on the `Use this template` > `Create a new repository` button and choose a name for your forked repository.
2. In [`apps/values.yaml`](apps/values.yaml) set `repoURL` to your forked repository url.
3. Deploy the app-of-apps Application using the [terragrunt-template-catalog-eks](https://github.com/ConsciousML/terragrunt-template-catalog-eks) catalog. 

The catalog provisions the Application CR with the correct `helm.values` (hostname, gateway, annotations) via the [`argocd_app_of_apps` module](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/modules/argocd_app_of_apps), [unit](https://github.com/ConsciousML/terragrunt-template-catalog-eks/tree/main/units/eks/addons/argocd/app_of_apps), and [stack](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/pipelines/dev/eks/stack/terragrunt.stack.hcl).

See [`app-of-apps.yaml`](app-of-apps.yaml) for the shape of the resource Terraform produces.

Access the ArgoCD UI and verify the `guestbook` app has been deployed.

### Adding an App

1. Create a directory for your application at the root of the repository. Plain manifest directories and Helm charts are both supported. See [`guestbook`](guestbook) as a reference.
2. In [`apps/values.yaml`](apps/values.yaml), under `applications`, add one entry with the directory name and target namespace.
3. For Helm chart apps that require runtime values, pass them via `spec.source.helm.values` on the app-of-apps Application CR. The `appParams.<app-name>` map is injected as a Helm values file into the child Application at sync time.

## Pre-commit Setup (recommended)
We use a more efficient framework than [pre-commit](https://github.com/pre-commit/pre-commit) called [prek](https://github.com/j178/prek).

### Installation

**Option 1: Use mise (recommended)**

First, `cd` at the root of this repository. 

Next, install mise:
```bash
curl https://mise.run | MISE_VERSION=v2026.4.0 sh
```

Then, install all the tools in the `mise.toml` file:
```bash
mise trust
mise install
```

Finally, run the following to automatically activate mise when starting a shell:
- For zsh: 
```bash
echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc && source ~/.zshrc
```
- For bash:
```bash
echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc && source ~/.bashrc
```

For more information on how to use mise, read their [getting started guide](https://mise.jdx.dev/getting-started.html).

**Option 2: Install Tools Manually**
- [Helm](https://helm.sh/docs/intro/install/)
- [Kubeconform](https://github.com/yannh/kubeconform#Installation)
- [prek](https://prek.j178.dev/installation/)

See [mise.toml](./mise.toml) for specific versions.

### Enable Pre-commit

Wire hooks automatically into git automatically:
```bash
chmod +x scripts/*.sh
prek install
```

Run hooks on demande:
```bash
prek run
```

## Continuous Integration (CI)

CI runs on every pull request via GitHub Actions. It installs tools with mise and runs all prek hooks (`validate-helm` and `validate-manifests`):

- `validate-helm`: runs `helm lint` and `helm template | kubeconform` on every chart discovered in the repo.
- `validate-manifests`: runs `kubeconform` on every plain Kubernetes manifest (YAML files not part of a Helm chart).

To trigger CI manually, use the **Run workflow** button on the [Actions tab](../../actions/workflows/ci.yaml).

## License
This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.