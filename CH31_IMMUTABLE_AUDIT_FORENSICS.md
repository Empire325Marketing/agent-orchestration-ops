# Chapter 31 — Immutable Audit & Forensics

## Decision Summary
Establish an **append-only, signed, hash-chained audit log** with chain-of-custody procedures and promotion gates. Logs are queryable,
tamper-evident, region-scoped (Ch.30), and tied to supply-chain attestations (Ch.10).

## Scope
- Event catalog + schema (standard fields; extensible).
- Hash chaining per partition with periodic **anchors** (daily).
- Optional signing of batches/anchors (conceptual; keys via Ch.8).
- Readiness gate + alerts + forensics runbook.

## Non-goals
- External ledger integration in MVP.
- Live cryptographic verification in request path (verification is async/off-path).

## Ties
Ch.6 (proxy), Ch.7 (observability), Ch.8 (secrets/IAM), Ch.9 (compliance/retention/legal-hold),
Ch.10 (supply chain signing/provenance), Ch.12 (cost), Ch.13 (readiness), Ch.15 (backups),
Ch.16 (lineage/contracts), Ch.23 (RBAC), Ch.24 (billing), Ch.30 (residency).

## Controls
1) **Append-only** storage (documented policy; rotation/retention runbook).
2) **Hash chain**: each record includes `hash_prev` → `hash_cur` (partition-scoped).
3) **Anchors**: daily anchor file with batch digest + (optional) signature.
4) **Coverage**: ≥95% of request traces (Ch.7) link to an audit record.
5) **Forensics**: chain-of-custody template; reproducible extraction; DECISIONS.log trail.

## Event Families
- user_action, system_action, model_inference, tool_call, data_access,
  admin_change, security_event, billing_event

## Readiness (see readiness/audit_gate.md)
- Pass only if: chain breaks=0 (24h), anchors present for last 2 days, coverage≥0.95, and retention hooks intact (Ch.9).

## Alerts (see observability/audit_alerts.prom)
- Chain break, missing anchor, admin_change spike, cross-tenant access attempt (Ch.23).

## Runbooks
- Forensics (collection → verification → report).
- Audit log rotation (WORM semantics, retention checks).
