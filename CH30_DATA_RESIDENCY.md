# Chapter 30 — Data Residency & Regionalization

## Decision Summary
Adopt region-scoped storage and routing with **US** and **EU** regions for MVP:
- Strict residency for HR/identifying PII; no cross-border at-rest replication.
- Region-aware request routing and egress controls.
- Region-isolated backups/keys; exports honor residency.

## Scope
- Inbound tagging (tenant->region), gateway routing, orchestrator enforcement.
- Storage: Postgres clusters per region; vector optional (Ch.3) follows region.
- Egress: proxy allow-list per region (Ch.6).
- Secrets: regional Vault namespaces/paths (conceptual; Ch.8).
- Compliance: matrices + DPIA linkage (Ch.9); offboarding/exports (Ch.25).
- Readiness gate + alerts; runbooks.

## Non-goals
- Multi-region active/active for the same tenant.
- Live cross-region replication of PII in MVP.

## Ties
Ch.6 (proxy), Ch.7 (observability), Ch.8 (secrets), Ch.9 (compliance),
Ch.12 (cost), Ch.13 (readiness), Ch.15 (backups), Ch.16 (lineage),
Ch.23 (RBAC), Ch.24 (billing), Ch.25 (exports).

## Enforcement Overview
1) **Classify** data (residency/data_classes.yaml).
2) **Route** by tenant region (residency/routing_policy.md).
3) **Store** only in-region (DB/backup paths).
4) **Block** cross-region PII flows (alerts + gate).
5) **Audit** with lineage & DECISIONS.log.
