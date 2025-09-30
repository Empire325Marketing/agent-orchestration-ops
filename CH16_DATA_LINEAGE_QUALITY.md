# Chapter 16 — Data Lineage & Quality Gates

## Decision Summary
We formalize **end-to-end lineage** and **dataset contracts** so every route/tool has clear producers/consumers, schemas, and invariants.
Quality rules become **gates**: failing checks block promotion (Ch.10), trigger alerts (Ch.7), and open an incident (runbooks/dq-incident.md).

## Scope
- Datasets: requests, tool_calls, messages, embeddings, evaluations (golden).
- Lineage graph from gateway → orchestrator → tools/LLM → Postgres/pgvector → analytics.
- Contracts declared in YAML with invariants; SQL checks for fast validation; Prometheus alert sketches.

## Non-Goals (MVP)
- Automated lineage UI; full data catalog; cross-workspace discovery.

## Ties to other chapters
- Ch.6 Sandbox (safe replay), Ch.7 Observability (alerts), Ch.8 Secrets/IAM (least-privilege reads),
  Ch.9 Compliance (PII flags, retention), Ch.10 CI/CD (gates), Ch.11 Runbooks, Ch.12 Cost (expensive checks capped),
  Ch.13 Readiness (quality thresholds), Ch.15 Backups (validate on restore).

## Gates (high level)
- **Perf:** see Ch.13 thresholds.
- **Quality:** golden win_rate ≥ 0.90; regression ≤ 5%.
- **Safety:** PII_leak=0; jailbreak=0 (curated set).
- **Data Quality:** contract checks must pass for all critical tables (see SQL & alerts).
