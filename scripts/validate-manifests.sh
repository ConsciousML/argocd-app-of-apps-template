#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# CRD schemas, not covered by kubeconform's default source
CRD_CATALOG='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

IGNORE_PATTERNS=(
  '(^|/)trivy\.yaml$'         # Trivy config, not a manifest
  '(^|/)\.trivyignore\.yaml$' # Trivy ignore file, not a manifest
  '(^|/)\.github/'             # workflow files
  # Helm chart source files are Go templates, not valid YAML on their own —
  # validated separately in validate-helm.sh via `helm template | kubeconform`.
  '(^|/)Chart\.yaml$'
  'values\.yaml$'
  '(^|/)templates/'
)

IGNORE_ARGS=()
for pattern in "${IGNORE_PATTERNS[@]}"; do
  IGNORE_ARGS+=(-ignore-filename-pattern "$pattern")
done

kubeconform \
  --strict \
  --ignore-missing-schemas \
  --schema-location default \
  --schema-location "$CRD_CATALOG" \
  --summary \
  "${IGNORE_ARGS[@]}" \
  "$REPO_ROOT"
