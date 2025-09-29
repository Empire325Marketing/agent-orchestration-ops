# Chapter 19 — Go-Live Cutover & Day-2 Ops

## Decision Summary
We enforce a controlled cutover with **freeze → shadow → 10% canary → stepwise rollout** guarded by readiness gates and automatic rollback on breach. Day-2 Ops includes on-call, comms, and post-launch checks.

## Scope (MVP)
- Cutover checklist & freeze policy
- Rollback plan wired to CI/CD (Ch.10), Readiness (Ch.13), Safety (Ch.17), Cost (Ch.12)
- On-call rota and launch comms
- Day-0/1/7 verification; Game-day tie-ins (Ch.15)
- Launch watchers (Prometheus) + DECISIONS logging

## Non-Goals
- Blue/green across regions; multi-tenant staged waves (post-MVP).

## Ties
- **Ch.6** Sandbox/Proxy allow-list honored during launch traffic.
- **Ch.7** OTel dashboards + alerts source of truth.
- **Ch.10** Canary 10% with auto-rollback; signed artifacts.
- **Ch.12** Cost headroom ≥ 20% or downgrade/rollback.
- **Ch.13** Gates: perf/quality/safety/cost/compliance must pass.
- **Ch.15** Backups/DR: restore validation before unfreeze.
- **Ch.17** Safety test sets must be zero-fail for promoted path.
- **Ch.18** Flags/experiments govern progressive exposure.
