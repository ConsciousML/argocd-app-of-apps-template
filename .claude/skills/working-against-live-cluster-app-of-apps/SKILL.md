---
name: working-against-live-cluster-app-of-apps
description: Loop for changes that must take effect on the live EKS cluster (edit, sync via ArgoCD, verify). Use whenever a goal requires actually applying a change to the live cluster, not just editing or planning source.
---

## Apply manifests through GitOps only

Never run `kubectl apply`, `create`, `patch`, or `edit` to change a resource's spec, unless the
user explicitly instructs it. ArgoCD is the only path from a file to a live resource here. A
live edit outside git gets pruned or drifts.

`kubectl rollout restart` is fine, it doesn't touch git-tracked spec, only triggers a new
rollout of the current one.

## Log in to ArgoCD

Check first with `argocd account get-user-info`. If it reports logged in, skip this step.

Otherwise, confirm Tailscale is connected, then log in with the command from
[Log in to ArgoCD](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/README.md#log-in-to-argocd)
in the catalog repo's README.

## The loop

1. Edit the file(s).
2. Commit and push. Match the existing style, a single-line `type(scope): summary` subject,
   no body.
3. If `prek`'s hook fails for a reason unrelated to the change (missing local tooling, not a
   real lint or validation failure), commit with `-n` and tell the user about the gap.
4. `argocd app list`, then sync only the affected app: `argocd app sync <app-name>`.
5. Verify against the live cluster not against the rendered manifest.
6. If verification fails, fix the file and resync.
