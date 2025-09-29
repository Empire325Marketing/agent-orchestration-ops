# Chapter 36 — Caching & Performance Acceleration

## Decision Summary
Introduce layered caching to reduce latency and cost while preserving safety, compliance, and correctness:
- **Request coalescing** (de-dup within a short window)
- **Result caching** for deterministic tool calls & read-only routes
- **Embeddings cache** (idempotent inputs)
- **Prompt/template cache** with versioned keys
- **Egress HTTP cache** only for allow-listed domains (Ch.6)

## Scope
Keying strategy, TTLs by route, PII-aware exclusions, invalidation triggers, observability, readiness gate, and runbooks.

## Non-goals
No CDN provisioning; no deployment of cache servers in this chapter (policies/docs only).

## Ties
Ch.6 (proxy/allow-list), Ch.7 (observability/SLO), Ch.11 (cache-busting runbook), Ch.12 (cost guardrails), 
Ch.13 (readiness), Ch.16 (data contracts), Ch.17/26 (safety), Ch.30 (residency).
