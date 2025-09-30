# Chapter 29 — Admin Console & Operator Dashboard

## Decision Summary
Ship a minimal web console for operators with RBAC-aware views and golden widgets.
Scope: read-only operational control + safe toggles that call existing runbooks and gates.
Ties: Ch.7 (observability), Ch.10 (CI/CD), Ch.12 (cost), Ch.13 (readiness), Ch.17 (safety), Ch.23 (RBAC), Ch.24 (billing), Ch.26 (firewall/personas).

## Non-goals
No multi-tenant customer UI; no direct schema mutations; no model tuning from console.

## Views (read-only unless noted)
- **Overview**: p95 latency, error budget burn, safety incidents, spend headroom.
- **Readiness**: gate status (perf/quality/safety/cost/compliance), promote/rollback links (Ch.10 rules).
- **Tenants**: tier, budgets (Ch.12), spend, export/offboarding status (Ch.25).
- **Safety**: jailbreak/PII rates (Ch.17), prompt firewall alerts (Ch.26).
- **Billing**: rollups, unpaid invoices (Ch.24).
- **Personas**: FRANK manifest status (Ch.28).
- **Incidents/Runbooks**: quick links to runbooks and last decisions.

## Security
RBAC via Ch.23; console routes are guarded and all actions are audited to DECISIONS.log.

## Readiness to Ship
Admin gate (readiness/admin_gate.md) must pass; dashboards green; rollback tested.
