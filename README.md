# ArgoCD App of Apps Template 

An ArgoCD template repository implementing the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative) with CI checks.

## Prerequisites
- A functional [terragrunt-template-catalog-eks](https://github.com/ConsciousML/terragrunt-template-catalog-eks) deployment. Its [EKS Cluster Stack](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/units/eks/README.md) provisions ArgoCD and the `argocd` namespace
- Knowledge of the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative)

## Getting Started

1. Click on the `Use this template` > `Create a new repository` button and choose a name for your forked repository.
2. In [`apps/values.yaml`](apps/values.yaml) set `repoURL` to your forked repository url.
3. Deploy the app-of-apps Application using the [terragrunt-template-catalog-eks](https://github.com/ConsciousML/terragrunt-template-catalog-eks) catalog. See its [App of Apps integration guide](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/docs/app-of-apps-integration.md) for how the catalog threads Terraform-sourced values into this chart's `appParams`.

Access the ArgoCD UI and verify the `podinfo` app has been deployed.

### Adding an App

1. Create a directory for your application at the root of the repository. Plain manifest directories and Helm charts are both supported. See [`podinfo`](podinfo) as a reference.
2. Add a `Namespace` manifest for your app's target namespace to [`namespace-pod-security-admission`](namespace-pod-security-admission) or sync fails. `privileged` unblocks local testing, but switch to `baseline` before merging unless the workload needs host access. See the [Pod Security Admission docs](https://kubernetes.io/docs/concepts/security/pod-security-admission/).
3. In [`apps/values.yaml`](apps/values.yaml), under `applications`, add one entry with the directory name and target namespace.
4. For Helm chart apps that require runtime values, pass them via `spec.source.helm.values` on the app-of-apps Application CR. The `appParams.<app-name>` map is injected as a Helm values file into the child Application at sync time. See the catalog's [App of Apps integration guide](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/docs/app-of-apps-integration.md) for the catalog-side steps to wire a new app's values.

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

Some charts leave required fields blank in `values.yaml` because they're filled in later, either through `apps/values.yaml`'s `extraValueFiles` or through the catalog's `appParams` injection. If `validate-helm` fails on one of these with a schema validation error, add a `placeholder-values.yaml` next to that chart's `values.yaml` with dummy values that satisfy the schema. `validate-helm.sh` picks it up automatically when present.

To trigger CI manually, use the **Run workflow** button on the [Actions tab](../../actions/workflows/ci.yaml).

Run `scripts/find-images.sh` to list every image (`repo:tag`, unresolved) referenced by charts and plain manifests, for offline scanning with tools like `trivy image`.

## License
This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.