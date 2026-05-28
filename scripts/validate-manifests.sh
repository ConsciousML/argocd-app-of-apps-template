#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
ERRORS=0

# Collect Helm chart root dirs to exclude their files
HELM_ROOTS=()
while IFS= read -r dir; do
  HELM_ROOTS+=("$dir")
done < <(find "$REPO_ROOT" -name Chart.yaml -not -path '*/.git/*' -exec dirname {} \;)

is_under_helm_chart() {
  local path="$1"
  for helm_root in "${HELM_ROOTS[@]}"; do
    if [[ "$path" == "$helm_root"/* ]]; then
      return 0
    fi
  done
  return 1
}

PLAIN_MANIFESTS=()
while IFS= read -r f; do
  if ! is_under_helm_chart "$f"; then
    PLAIN_MANIFESTS+=("$f")
  fi
done < <(find "$REPO_ROOT" -name '*.yaml' -not -path '*/.git/*' -not -path '*/.github/*')

if [[ ${#PLAIN_MANIFESTS[@]} -eq 0 ]]; then
  echo "No plain manifests found."
  exit 0
fi

for manifest in "${PLAIN_MANIFESTS[@]}"; do
  rel="${manifest#"$REPO_ROOT/"}"
  echo "==> kubeconform: $rel"
  if ! conform_output="$(kubeconform --strict --summary "$manifest" 2>&1)"; then
    echo "FAIL: kubeconform failed for $rel"
    echo "$conform_output"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "Manifest validation failed with $ERRORS error(s)."
  exit 1
fi

echo "Manifest validation passed."
