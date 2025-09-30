# Chapter 0 — Scope, Roles, Source-of-Truth

## Roles & RACI

- **Operator (iii)**: owns goals, legal sign-off, budget, approvals.
- **Executor (Claude on server)**: writes/updates docs in /srv/primarch; prepares runbooks and plans; no external calls.
- **Ops (placeholder)**: will later run infra commands and deployments.

## Source-of-Truth

- **Directory**: /srv/primarch (all docs/config drafts live here).
- **Change control**: edits only via tracked decisions in DECISIONS.log.

## MVP Scope (frozen for MVP)

- **API gateway**: one (TBD in Ch1).
- **Orchestrator**: one (internal MVP, upgrade path to Temporal).
- **Storage**: Postgres for OLTP/memory; optional Qdrant for vectors.
- **Inference**: one on-prem LLM runtime on RTX 5090.
- **Egress**: one proxy for outbound search APIs (allow-list).
- **Telemetry**: OTel collector with tail sampling.
- **Secrets**: Vault on-prem.
- **CI**: GitHub Actions (canary + rollback).

## Success Criteria (Done-when for MVP)

- End-to-end "DB-as-memory → tool call → response" flow works locally.
- Observability pages SLI/SLO (p95 latency + error budget) present.
- Compliance binder (retention matrix draft + DPIA/AIA skeleton) exists.

## Guardrails

- Data minimization, region routing for HR PII, least privilege IAM.
- Network-off sandbox default; proxy allow-list only.

## Out-of-Scope for MVP

- Multi-region HA, Kubernetes, full HRIS integrations (beyond stubs).
- Production incident automation (beyond runbook drafts).