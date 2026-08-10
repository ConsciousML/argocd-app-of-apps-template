# Discovery helpers sourced by scripts/*.sh. Not meant to be run directly.

REPO_ROOT="$(git rev-parse --show-toplevel)"

# CRD schemas, not in kubeconform's default source
CRD_CATALOG='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

KUBECONFORM_ARGS=(
  --strict
  --ignore-missing-schemas
  --schema-location default
  --schema-location "$CRD_CATALOG"
  --summary
)

# Non-manifest files: Helm chart source (Go templates) and tooling config.
PLAIN_MANIFEST_IGNORE_PATTERNS=(
  '(^|/)trivy\.yaml$'
  '(^|/)\.trivyignore\.yaml$'
  '(^|/)\.github/'
  '(^|/)Chart\.yaml$'
  'values\.yaml$'
  '(^|/)templates/'
)

# Prints each Helm chart's directory, one per line.
find_helm_charts() {
  find "$REPO_ROOT" -name Chart.yaml -not -path '*/.git/*' -exec dirname {} \;
}

# Prints every plain-manifest YAML file, one per line.
find_plain_manifests() {
  local combined
  combined="$(IFS='|'; echo "${PLAIN_MANIFEST_IGNORE_PATTERNS[*]}")"
  find "$REPO_ROOT" -not -path '*/.git/*' \( -name '*.yaml' -o -name '*.yml' \) |
    grep -Ev "$combined"
}

# Echoes a chart's placeholder-values.yaml, if present.
placeholder_values_file() {
  local chart_dir="$1"
  local file="$chart_dir/placeholder-values.yaml"
  [[ -f "$file" ]] && echo "$file"
  return 0
}
