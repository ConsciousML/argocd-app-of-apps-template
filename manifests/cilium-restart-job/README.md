# cilium-restart-job

One-shot `Job` that rolls out any Deployment, StatefulSet, or DaemonSet with a pod missing a `CiliumEndpoint`. Cilium only manages pods created after `cilium-agent` is already running on their node, so pods predating it (any bootstrap-time workload) stay invisible to Cilium and get dropped by any `CiliumNetworkPolicy` that isn't `world`-permissive.

Applied with plain `kubectl apply`, not through app-of-apps. It needs to run after Cilium and its network policies are up, and re-running it is safe since it skips pods that already have a `CiliumEndpoint`.

## What's Inside

- **[serviceaccount.yaml](serviceaccount.yaml)**: identity the Job runs as
- **[clusterrole.yaml](clusterrole.yaml)** and **[clusterrolebinding.yaml](clusterrolebinding.yaml)**: read-only access to list pods, namespaces, and `ciliumendpoints.cilium.io` cluster-wide, plus `get`, `patch`, and `watch` on Deployments, StatefulSets, and DaemonSets to trigger and wait on a rollout
- **[configmap.yaml](configmap.yaml)**: the discovery and restart script, mounted into the Job's container
- **[job.yaml](job.yaml)**: runs the script on `alpine/k8s`, waits up to 10m per rollout, then re-scans and fails if any pod is still missing a `CiliumEndpoint`
