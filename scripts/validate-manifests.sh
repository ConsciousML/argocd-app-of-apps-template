#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
ERRORS=0

# Kinds with no reliable kubeconform schema source yet — tracked in
# https://github.com/ConsciousML/argocd-app-of-apps-template/issues/6
SKIP_KINDS="Application,SecretStore,ExternalSecret,GatewayClass,TargetGroupConfiguration,LoadBalancerConfiguration,Connector"

# Tool config files, not Kubernetes manifests
NON_MANIFEST_FILES=("$REPO_ROOT/trivy.yaml" "$REPO_ROOT/.trivyignore.yaml")

is_non_manifest_file() {
  local path="$1"
  for f in "${NON_MANIFEST_FILES[@]}"; do
    if [[ "$path" == "$f" ]]; then
      return 0
    fi
  done
  return 1
}

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
  if ! is_under_helm_chart "$f" && ! is_non_manifest_file "$f"; then
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
  if ! conform_output="$(kubeconform --strict --ignore-missing-schemas --skip "$SKIP_KINDS" --summary "$manifest" 2>&1)"; then
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
