# Chapter 35 — Model Registry & Lifecycle

## Decision Summary
Establish a **Model Registry** with promotion stages (experimental → shadow → canary → production), tight integration with
**Readiness Gates (Ch.13)**, **Safety (Ch.17/26)**, **Supply Chain (Ch.10)**, and **Audit/Forensics (Ch.31)**. All model
changes produce signed artifacts, evaluations, and an append-only audit trail.

## Scope
- Canonical registry of models and routes, metadata, policies, and owners.
- Promotion policy gated by: eval quality ≥ thresholds, safety ≡ pass (0 jailbreak/PII), perf within SLO, cost headroom ≥ 20%.
- Rollback + downgrade ladder tied to GPU pools (Ch. GPU Pools Update) and brownout policy.
- Model cards templated & required for GA.

## Non-goals
- Hosting/serving configuration (covered in Ch.4 runtime + GPU pools).
- Training pipelines (future work).

## Ties
Ch.4 (runtime), Ch.7 (observability), Ch.10 (CI/CD & provenance), Ch.13 (readiness), Ch.17/26 (safety),
Ch.20 (analytics), Ch.31 (audit), Ch.33 (SIEM).
