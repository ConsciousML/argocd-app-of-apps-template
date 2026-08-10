#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/discovery.sh"

# Helm chart source files are Go templates, not valid YAML on their own.
# validate-helm.sh covers them separately via `helm template | kubeconform`.
FILES=()
while IFS= read -r file; do
  FILES+=("$file")
done < <(find_plain_manifests)

kubeconform "${KUBECONFORM_ARGS[@]}" "${FILES[@]}"
