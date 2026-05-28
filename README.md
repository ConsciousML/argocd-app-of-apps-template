# ArgoCD App of Apps Template 

An ArgoCD template repository implementing the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative) with CI checks.

## Prerequisites
- A functional ArgoCD instance
- Knowledge of the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative)

## Usage
1. Click on the `Use this template` > `Create a new repository` button and choose a name for your forked repository.
2. In [`apps/values.yaml`](apps/values.yaml) set `repoURL` to your forked repository url.
3. Create a directory for each application you want ArgoCD to deploy in your cluster. Use the [argocd-example-apps](https://github.com/argoproj/argocd-example-apps) repository as a reference.
4. In [`apps/values.yaml`](apps/values.yaml), under `applications`, add one entry per application (see the [the reference `values.yaml`](https://github.com/argoproj/argocd-example-apps/blob/master/apps/values.yaml))
5. 

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