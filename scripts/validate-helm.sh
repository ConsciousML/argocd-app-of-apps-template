#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
ERRORS=0

# CRD schemas, not covered by kubeconform's default source
CRD_CATALOG='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

KUBECONFORM_ARGS=(
  --strict
  --ignore-missing-schemas
  --schema-location default
  --schema-location "$CRD_CATALOG"
  --summary
)

# Get all the directory paths containing Helm Charts
HELM_CHARTS=()
while IFS= read -r dir; do
  echo "[INFO] Found chart: ${dir#"$REPO_ROOT"/}"
  HELM_CHARTS+=("$dir")
done < <(find "$REPO_ROOT" -name Chart.yaml -not -path '*/.git/*' -exec dirname {} \;)

if [[ ${#HELM_CHARTS[@]} -eq 0 ]]; then
  echo "[INFO] No Helm charts found."
  exit 0
fi

for chart_dir in "${HELM_CHARTS[@]}"; do
  rel="${chart_dir#"$REPO_ROOT/"}"

  echo "[INFO] Building Helm dependencies: $rel"
  if ! dep_output="$(helm dependency build "$chart_dir" 2>&1)"; then
    echo "[ERROR] helm dependency build failed for $rel"
    echo "$dep_output"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  echo "[INFO] Linting Helm chart: $rel"
  if ! lint_output="$(helm lint "$chart_dir" 2>&1)"; then
    echo "[ERROR] helm lint failed for $rel"
    echo "$lint_output"
    ERRORS=$((ERRORS + 1))
  fi

  template_args=("$chart_dir")
  placeholder_values="$chart_dir/placeholder-values.yaml"
  if [[ -f "$placeholder_values" ]]; then
    template_args+=(-f "$placeholder_values")
  fi

  echo "[INFO] Rendering templates: $rel"
  template_output="$(helm template "${template_args[@]}" 2>&1)" || {
    echo "[ERROR] helm template failed for $rel"
    echo "$template_output"
    ERRORS=$((ERRORS + 1))
    continue
  }

  echo "[INFO] Validating rendered manifests against schemas: $rel"
  if ! conform_output="$(echo "$template_output" | kubeconform "${KUBECONFORM_ARGS[@]}" 2>&1)"; then
    echo "[ERROR] kubeconform failed for $rel"
    echo "$conform_output"
    ERRORS=$((ERRORS + 1))
  fi
done

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "[ERROR] Helm validation failed with $ERRORS error(s)."
  exit 1
fi

echo "[INFO] Helm validation passed."
