---
name: how-to-write-docs
description: Rules for writing or editing Markdown docs or inline code comments in this repo (README.md, docs/, manifests, chart docs, comments). Use before writing or editing any doc or comment.
---

Follow [terragrunt-template-catalog-eks's `how-to-write-docs`
skill](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/.claude/skills/how-to-write-docs/SKILL.md)
first, these rules extend it and don't repeat it.

## Dependency Injection

- Every value the catalog's `app_of_apps` unit injects into a chart via `appParams` must be
  documented in that chart. Add a comment on the field in its `values.yaml`, then point to it
  from the README instead of repeating the explanation.
- Every `extraValueFiles` entry in `apps/values.yaml` must be documented in the consuming
  chart's README. If an example in `apps/README.md` describes the mechanism, keep it pointed at
  a real, current entry, not a stale one.
