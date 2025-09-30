# Chapter 20 — Post-Launch Analytics & Learnings

## Decision Summary
We standardize a post-launch learning loop: instrument → review → decide → act. KPIs and guardrail metrics are versioned, queryable, and gated through CI/CD and Readiness.

## Scope (MVP)
- KPI tree & metric catalog with owners and sources
- Standard queries for Postgres/OTel/Prom
- Recording rules for derived metrics (Prometheus)
- Day-7 learning review + backlog intake
- Blameless postmortem template

## Non-Goals
- Full data warehouse modeling; ML attribution beyond basic funnels.

## Ties
- **Ch.7** Observability metrics as sources of truth
- **Ch.10** CI gates use KPIs as promotion checks
- **Ch.12** Cost KPIs (cost/req, tenant headroom)
- **Ch.13** Readiness thresholds echoed here
- **Ch.17** Safety rates (jailbreak/PII/toxicity)
- **Ch.19** Day-0/1/7 checklists feed this review
