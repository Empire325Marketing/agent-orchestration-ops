# Docs Policy (Conceptual CI Gates)

Required checks on PRs that touch:
- API routes, tools, or user-visible behavior → must update KB and changelog.
- Add `docs:affected` label or CI auto-detects via path rules.

Gates:
- Lint (markdown headings/links), dead-link check (internal paths), ownership labels.
- Fail release if `docs_required=true` and KB diffs are missing (ties to Ch.10).
