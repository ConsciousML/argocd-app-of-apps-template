#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/discovery.sh"
cd "$REPO_ROOT"

# Charts with a required value (no default, e.g. clusterName, bucketNames) fail to
# render at all without one, and Trivy silently skips scanning them rather than
# failing. Feed every placeholder-values.yaml in, same as validate-helm.sh does for
# helm template/kubeconform, so those charts actually get scanned instead of skipped.
HELM_VALUES_ARGS=()
while IFS= read -r chart_dir; do
  placeholder_values="$(placeholder_values_file "$chart_dir")"
  if [[ -n "$placeholder_values" ]]; then
    HELM_VALUES_ARGS+=(--helm-values "${placeholder_values#"$REPO_ROOT"/}")
  fi
done < <(find_helm_charts)

trivy config --config trivy.yaml --ignorefile .trivyignore.yaml "${HELM_VALUES_ARGS[@]}" .
