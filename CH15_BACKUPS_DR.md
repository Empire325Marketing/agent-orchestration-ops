# Chapter 15 — Backups & Disaster Recovery

## Decision Summary
- **Goal:** Ensure reliable, verifiable backups with fast restore and routine game-days.
- **Strategy:** Logical + physical backups where appropriate, encrypted at rest; scheduled verifies; periodic restore drills.
- **Targets:** Dataset-specific RPO/RTO (see `backups/backup_matrix.yaml`).
- **Verification:** Checksums + automated **restore validation** to an isolated environment with data minimization.
- **Governance:** Results logged in `DECISIONS.log` and referenced in compliance audit runbook.

## Scope
- PostgreSQL OLTP (pgvector tables included)
- Vault metadata/config (no secrets content here; see Ch.8 for policies)
- Tool registry & CI artifacts metadata
- Observability configs needed to rebuild dashboards/alerts

## Non-Goals (MVP)
- Cross-region hot-hot replication
- Hardware HSM backup/export procedures
- Fully automated DR failover (covered later; see failover runbook for manual steps)

## RPO / RTO Objectives
- **Postgres:** RPO ≤ 15m (WAL+base), RTO ≤ 30m.
- **Vault metadata/policies:** RPO ≤ 24h, RTO ≤ 60m.
- **Tool/CI metadata:** RPO ≤ 24h, RTO ≤ 60m.

## Schedules & Retention
- Nightly full + 15m WAL for Postgres. Weekly synthetic full.
- Retention: 30 days (Postgres), 90 days (policy/metadata), legal holds per Ch.9.

## Verifications
- Nightly checksum verify; daily automated **restore validation** (see `backups/restore_validation.md`).
- Game-day once per month (see `runbooks/game-day.md`).

## Ties to other chapters
- Ch.6 Sandbox/Proxy (isolation during restores)
- Ch.7 Observability (backup freshness/last_success alerts)
- Ch.8 Secrets/IAM (access to backup locations; no secrets printed)
- Ch.9 Compliance (retention, legal hold, DPIA hooks)
- Ch.10 CI/CD (gates before promotion if restore validation failing)
- Ch.11 Runbooks (incident, failover-DR)
- Ch.12 Cost guardrails (storage budgets)
- Ch.13 Readiness gates (block rollout on failing restore tests)
