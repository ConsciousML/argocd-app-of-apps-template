# `priority-classes` Manifests Reference

The [`priority-classes` manifests](./) define `daemonset-critical`, a `PriorityClass` for cluster-wide DaemonSets (Alloy, Loki's canary, `prometheus-node-exporter`) that must land on every node, including ones a lower-priority workload already filled up.

## What's Inside

- **[daemonset-critical.yaml](daemonset-critical.yaml)**: the highest user-defined value Kubernetes allows, below the built-in `system-cluster-critical` and `system-node-critical`. Preempts ordinary workloads, never a cluster-critical controller like Karpenter or the ArgoCD application-controller

## Naming

<!-- MIGRATE: explanation, move to the site's explanation docs -->
Named without the `system-` prefix since Kubernetes reserves that for its own built-in priority classes.
