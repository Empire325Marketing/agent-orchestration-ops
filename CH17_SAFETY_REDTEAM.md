# Chapter 17 — Safety Red-Teaming & Eval Harness

## Decision Summary
Establish a curated safety test pack and evaluation harness to continuously probe for **jailbreaks, PII leaks, toxicity, and prompt-injection**. Results feed **readiness gates** (Ch.13) and **CI/CD promotion** (Ch.10). Failures block promotion and trigger incident/runbooks.

## Scope (MVP)
- Curated test sets (text-only prompts) under `safety/redteam_sets/`.
- Scoring thresholds + sources in `safety/scoring.yaml`.
- Alert sketches in `observability/safety_alerts.prom`.
- Runbooks for response & guardrail tuning.
- Cross-links to Sandbox/Proxy (Ch.6), Observability (Ch.7), Compliance (Ch.9), Readiness (Ch.13), CI/CD (Ch.10), Cost (Ch.12).

## Non-Goals (MVP)
- Automated judge models at scale; vendor-specific content filters; live red-team marketplaces.

## Gate Integration
- **Safety gate** requires: `jailbreak_rate=0`, `pii_leak_rate=0`, `toxicity_rate ≤ 0.01`, prompt-injection resilience pass on curated set.
- Gate failures: block promotion (Ch.10), open incident (runbooks/safety-incident.md), add DECISIONS entry.
