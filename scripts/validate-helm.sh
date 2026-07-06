#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
ERRORS=0

HELM_CHARTS=()
while IFS= read -r dir; do
  HELM_CHARTS+=("$dir")
done < <(find "$REPO_ROOT" -name Chart.yaml -not -path '*/.git/*' -exec dirname {} \;)

if [[ ${#HELM_CHARTS[@]} -eq 0 ]]; then
  echo "No Helm charts found."
  exit 0
fi

for chart_dir in "${HELM_CHARTS[@]}"; do
  rel="${chart_dir#"$REPO_ROOT/"}"

  echo "==> helm dependency build: $rel"
  if ! dep_output="$(helm dependency build "$chart_dir" 2>&1)"; then
    echo "FAIL: helm dependency build failed for $rel"
    echo "$dep_output"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  echo "==> helm lint: $rel"
  if ! lint_output="$(helm lint "$chart_dir" 2>&1)"; then
    echo "FAIL: helm lint failed for $rel"
    echo "$lint_output"
    ERRORS=$((ERRORS + 1))
  fi

  echo "==> helm template | kubeconform: $rel"
  template_output="$(helm template "$chart_dir" 2>&1)" || {
    echo "FAIL: helm template failed for $rel"
    echo "$template_output"
    ERRORS=$((ERRORS + 1))
    continue
  }
  if ! conform_output="$(echo "$template_output" | kubeconform --strict --ignore-missing-schemas --summary 2>&1)"; then
    echo "FAIL: kubeconform failed for $rel"
    echo "$conform_output"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "Helm validation failed with $ERRORS error(s)."
  exit 1
fi

echo "Helm validation passed."
