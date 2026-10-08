---
name: reference-docs-app-of-apps
description: Rules for writing or editing a reference doc in this repo, a chart README.md.gotmpl, a values.yaml comment, or a manifest README. Use before writing or editing one. Not for tutorials, how-tos, or explanations.
---

Follow these terragrunt-template-catalog-eks skills first. These rules extend them and don't
repeat them:

- Docs: [`reference-docs-catalog`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/.claude/skills/reference-docs-catalog/SKILL.md)
- Comments: [`inline-comments-catalog`](https://github.com/ConsciousML/terragrunt-template-catalog-eks/blob/main/.claude/skills/inline-comments-catalog/SKILL.md)

## Scope

- Chart `README.md.gotmpl` and `values.yaml` comments, and manifest READMEs under `manifests/`.
- Never write a chart `README.md`, CI generates it with helm-docs. See
  `docs/document-a-helm-chart.md` for the template structure.
- Tutorials, how-tos, and explanations under `docs/` belong to the `eks-forge` agent. There, fix
  only a fact your change made wrong.

## Dependency Injection

- Every value the catalog's `app_of_apps` unit injects into a chart via `appParams` must be
  documented in that chart. Add a comment on the field in its `values.yaml`, then point to it
  from the README instead of repeating the explanation.
- Every `extraValueFiles` entry in `apps/values.yaml` must be documented in the consuming
  chart's README. If an example in `apps/README.md` describes the mechanism, keep it pointed at
  a real, current entry, not a stale one.
