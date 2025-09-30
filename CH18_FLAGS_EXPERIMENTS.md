# Chapter 18 — Feature Flags & Experimentation

## Decision Summary
Adopt **feature flags** for safe toggles and **experimentation** (A/B, shadow, stepwise rollout) to validate performance, quality, safety, cost, and compliance before full release.

## Scope (MVP)
- Flag catalog (`/flags/flags.yaml`) with owners, defaults, expiry windows, and links to runbooks.
- Experiment catalog (`/experiments/experiments.yaml`) with variants, allocation, guardrails, and promotion/rollback rules.
- Observability hooks (`/observability/exp_metrics.prom`) and readiness tie-ins (`/readiness/experiments_gate.md`).
- Runbook (`/experiments/runbook.md`) for lifecycle: propose → review → launch → monitor → decide → archive.

## Non-Goals (MVP)
- Realtime assignment SDKs; external flag services; bandit optimization (future).

## Ties
- **Ch.10 CI/CD**: promotion blocks on experiment guardrail breaches.
- **Ch.13 Readiness**: experiments must meet gates before promotion.
- **Ch.17 Safety**: safety gate must pass for treatment variants.
- **Ch.12 Cost**: auto-downgrade if spend headroom < 20%.
- **Ch.7 Observability**: p95/error-rate tracked per variant.
