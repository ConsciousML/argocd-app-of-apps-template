#!/usr/bin/env bash
set -euo pipefail

# Scans every image discovered by find-images.sh with `trivy image` and displays
# HIGH/CRITICAL findings. Non-blocking: vulnerabilities never fail the scan.

source "$(dirname "${BASH_SOURCE[0]}")/lib/discovery.sh"
cd "$REPO_ROOT"

ERRORS=0

if ! images="$("$(dirname "${BASH_SOURCE[0]}")/find-images.sh")"; then
  echo "[ERROR] find-images.sh reported errors; scanning whatever images were discovered." >&2
  ERRORS=$((ERRORS + 1))
fi

while IFS= read -r image; do
  [[ -z "$image" ]] && continue

  echo "[INFO] Scanning image: $image"
  trivy image --severity HIGH,CRITICAL --exit-code 0 "$image"
done <<<"$images"

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "[ERROR] Image vulnerability scan failed with $ERRORS error(s)."
  exit 1
fi

echo "[INFO] Image vulnerability scan passed."
