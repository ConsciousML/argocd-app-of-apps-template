# How to Write Docs

Documentation rules specific to this repo. Read [terragrunt-template-catalog-eks's `docs/how-to-write-docs.md`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/docs/how-to-write-docs.md) first, these rules extend it and don't repeat it.

## Dependency Injection

- Every value the catalog's `app_of_apps` unit injects into a chart via `appParams` must be documented in that chart. Add a comment on the field in its `values.yaml`, then point to it from the README instead of repeating the explanation.
- Every `extraValueFiles` entry in `apps/values.yaml` must be documented in the consuming chart's README. If an example in `apps/README.md` describes the mechanism, keep it pointed at a real, current entry, not a stale one.
