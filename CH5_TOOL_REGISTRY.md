# Chapter 5 — Tool & API Registry (MVP)

## Decision Summary
The registry format uses a single YAML file called tool_registry.yaml as the source of truth. Authentication is managed through Vault-backed secrets with OIDC where supported and API keys otherwise. Backoff follows exponential with full jitter and idempotency keys where applicable. Fallback order prioritizes local first, then cached snapshot, then secondary provider where policy permits.

## SLO Targets (by class)
Gateway and orchestrator components target p95 ≤ 150 ms with availability ≥ 99.9%. Internal database and vector operations target p95 ≤ 20 ms locally with availability ≥ 99.9%. External APIs are provider-dependent, budgeted per tenant with timeouts ≤ 3 seconds.

## Observability
Each call emits spans with attributes including tool_name, tenant_id, route, attempt, status, and latency_ms. Metrics cover requests, errors, p50/p95 latencies, throttled requests, and costs when available.

## Risk & Controls
PII tiers are classified as none, low, or high per tool, with high-PII denied to non-regional endpoints. Rate limits are enforced at both gateway and client level with circuit breakers on consecutive failures.

## Done-when
The tool_registry.yaml exists and validates visually. Tool specification stubs exist in the tool_specs directory. Runbooks for tool fallbacks and secrets rotation are complete. PROJECT_STATUS shows Chapter 5 checked. DECISIONS.log has a new timestamped Chapter 5 entry.