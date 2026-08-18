# Working Against the Live Cluster

When a goal must actually take effect on the live EKS cluster, use this loop instead of
touching the cluster directly.

## Never apply manifests directly

Never run `kubectl apply`, `create`, `patch`, or `edit` against the cluster. ArgoCD is the
only path from a file to a live resource here. A live edit outside git gets pruned or drifts.

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

