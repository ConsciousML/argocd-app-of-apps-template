#!/usr/bin/env bash
set -euo pipefail

# Lists container images (repo:tag, unresolved) referenced in charts and plain
# manifests. Stdout: per-source output, then a deduped aggregate at the end.

source "$(dirname "${BASH_SOURCE[0]}")/lib/discovery.sh"

ERRORS=0
IMAGES_TMP="$(mktemp)"
trap 'rm -f "$IMAGES_TMP"' EXIT

extract_images() {
  grep -oE '^- image: .+' | sed -E 's/^- image: //'
}

while IFS= read -r chart_dir; do
  rel="${chart_dir#"$REPO_ROOT"/}"

  echo "[INFO] Building Helm dependencies: $rel" >&2
  if ! dep_output="$(helm dependency build "$chart_dir" 2>&1)"; then
    echo "[ERROR] helm dependency build failed for $rel" >&2
    echo "$dep_output" >&2
    ERRORS=$((ERRORS + 1))
    continue
  fi

  template_args=("$chart_dir")
  placeholder_values="$(placeholder_values_file "$chart_dir")"
  [[ -n "$placeholder_values" ]] && template_args+=(-f "$placeholder_values")

  echo "[INFO] Discovering images: $rel" >&2
  if ! template_output="$(helm template "${template_args[@]}" 2>&1)"; then
    echo "[ERROR] helm template failed for $rel" >&2
    echo "$template_output" >&2
    ERRORS=$((ERRORS + 1))
    continue
  fi

  if ! kbld_output="$(echo "$template_output" | kbld -f - --unresolved-inspect 2>&1)"; then
    echo "[ERROR] kbld failed for $rel" >&2
    echo "$kbld_output" >&2
    ERRORS=$((ERRORS + 1))
    continue
  fi

  echo "$kbld_output" | grep -v '^null$' || true
  echo "$kbld_output" | extract_images >>"$IMAGES_TMP" || true
done < <(find_helm_charts)

PLAIN_MANIFESTS=()
while IFS= read -r file; do
  PLAIN_MANIFESTS+=(-f "$file")
done < <(find_plain_manifests)

if [[ ${#PLAIN_MANIFESTS[@]} -gt 0 ]]; then
  echo "[INFO] Discovering images in plain manifests" >&2
  if ! kbld_output="$(kbld "${PLAIN_MANIFESTS[@]}" --unresolved-inspect 2>&1)"; then
    echo "[ERROR] kbld failed for plain manifests" >&2
    echo "$kbld_output" >&2
    ERRORS=$((ERRORS + 1))
  else
    echo "$kbld_output" | grep -v '^null$' || true
    echo "$kbld_output" | extract_images >>"$IMAGES_TMP" || true
  fi
fi

echo "" >&2
echo "[INFO] All images (deduped):" >&2
sort -u "$IMAGES_TMP"

if [[ $ERRORS -gt 0 ]]; then
  echo "" >&2
  echo "[ERROR] Image discovery failed with $ERRORS error(s)." >&2
  exit 1
fi
