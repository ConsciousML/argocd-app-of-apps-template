# ArgoCD App of Apps Template 

An ArgoCD template repository implementing the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative).

## Prerequisites
- A functional ArgoCD instance
- Knowledge of the [App of Apps pattern](https://argo-cd.readthedocs.io/en/latest/operator-manual/cluster-bootstrapping/#app-of-apps-pattern-alternative)

## Usage
1. Click on the `Use this template` > `Create a new repository` button and choose a name for your forked repository.
2. In [`apps/values.yaml`](apps/values.yaml) set `repoURL` to your forked repository url.
3. Create a directory for each application you want ArgoCD to deploy in your cluster. Use the [argocd-example-apps](https://github.com/argoproj/argocd-example-apps) repository as a reference.
4. In [`apps/values.yaml`](apps/values.yaml), under `applications`, add one entry per application (see the [the reference `values.yaml`](https://github.com/argoproj/argocd-example-apps/blob/master/apps/values.yaml))
5. 

## License
This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.