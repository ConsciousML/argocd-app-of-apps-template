#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Charts with a required value (no default, e.g. clusterName, bucketNames) fail to
# render at all without one, and Trivy silently skips scanning them rather than
# failing. Feed every placeholder-values.yaml in, same as validate-helm.sh does for
# helm template/kubeconform, so those charts actually get scanned instead of skipped.
HELM_VALUES_ARGS=()
while IFS= read -r file; do
  HELM_VALUES_ARGS+=(--helm-values "${file#"$REPO_ROOT"/}")
done < <(find "$REPO_ROOT" -name placeholder-values.yaml -not -path '*/charts/*')

trivy config --config trivy.yaml --ignorefile .trivyignore.yaml "${HELM_VALUES_ARGS[@]}" .
