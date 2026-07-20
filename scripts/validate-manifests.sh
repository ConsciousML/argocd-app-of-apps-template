#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# Kinds with no reliable kubeconform schema source yet — tracked in
# https://github.com/ConsciousML/argocd-app-of-apps-template/issues/6
SKIP_KINDS="Application,SecretStore,ExternalSecret,GatewayClass,TargetGroupConfiguration,LoadBalancerConfiguration,Connector"

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
  --skip "$SKIP_KINDS" \
  --summary \
  "${IGNORE_ARGS[@]}" \
  "$REPO_ROOT"
