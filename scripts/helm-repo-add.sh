#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

# Discover every "repository:" URL declared under Chart.yaml dependencies,
# so adding a new chart never requires touching this script.
REPO_URLS="$(
  find "$REPO_ROOT" -name Chart.yaml -not -path '*/.git/*' -print0 |
    xargs -0 grep -h -E '^[[:space:]]*repository:[[:space:]]*https?://' |
    sed -E 's/^[[:space:]]*repository:[[:space:]]*//' |
    sort -u
)"

if [[ -z "$REPO_URLS" ]]; then
  echo "No Helm chart repositories to add."
  exit 0
fi

while IFS= read -r url; do
  # Derive a stable repo name from the host, since it's only used locally as an alias.
  name="$(echo "$url" | sed -E 's#^https?://##; s#/.*##; s/[^a-zA-Z0-9]+/-/g')"
  echo "==> helm repo add $name $url"
  helm repo add "$name" "$url" --force-update
done <<< "$REPO_URLS"

helm repo update
