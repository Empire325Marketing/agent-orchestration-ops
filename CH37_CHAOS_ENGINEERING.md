# Chapter 37 — Chaos Engineering & Fault Injection

## Decision Summary
Exercise controlled failures to prove resilience and validate gates before promotion:
- Failure modes: infra (VM/node/GPU), platform (proxy, DB, cache, model runtime), dependency (tools), and safety systems.
- Experiments: kill, degrade (latency/packet loss), brownout, partial outage, data-path toggle, and rollback drills.

## Scope
Experiment catalog, guardrails (blast radius ≤ canary), observability tie-ins, readiness gate, runbooks, and reporting queries.

## Non-goals
No live chaos in production by default; no automation against non-allowlisted systems.

## Ties
Ch.7 (SLO/alerts), Ch.11 (runbooks), Ch.12 (cost guardrails), Ch.15 (DR), Ch.17/26 (safety), Ch.19 (cutover),
Ch.30 (residency), Ch.31/33/34 (audit, SIEM, vuln), Ch.35 (model lifecycle), Ch.36 (caching).
