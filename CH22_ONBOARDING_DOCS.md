# Chapter 22 — User Onboarding & Docs

## Decision Summary
Provide a structured, versioned knowledge base with style and CI policies so users can self-serve from first run to advanced ops. In-product tips reference the same sources to avoid drift.

## Scope (MVP)
- KB structure with Getting Started, Quickstart, Concepts, API Reference, Troubleshooting, FAQ.
- Style guide + voice & tone.
- In-product tips (JSON spec) keyed by route/feature.
- Changelog + release notes template.
- Docs policy for CI gating (lint, linkcheck, ownership).
- Observability: basic "docs freshness" signals.

## Non-Goals
- No external site build; this is content + policies only.

## Integrations
- **Ch.7 Observability**: docs freshness/coverage metrics + alerts.
- **Ch.10 CI/CD**: docs checks required on PRs touching user-facing endpoints.
- **Ch.13 Readiness**: promotion blocked if required docs deltas missing.
- **Ch.20 Analytics**: capture top KB queries and feedback themes.
