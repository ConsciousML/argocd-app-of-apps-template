# priority-classes

Defines `daemonset-critical`, a `PriorityClass` for cluster-wide DaemonSets (Alloy, Loki's canary, `prometheus-node-exporter`) that need to land on every node, including ones a lower-priority workload already filled up.

## What's Inside

- **[daemonset-critical.yaml](daemonset-critical.yaml)**: valued one below the built-in `system-cluster-critical`, so it can preempt ordinary workloads to fit but can never preempt a cluster-critical controller like Karpenter or the ArgoCD application-controller. Named without the `system-` prefix since Kubernetes reserves that for its own built-in priority classes
