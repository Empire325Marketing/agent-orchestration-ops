# Failure Modes (Catalog)
- Proxy/Sandbox outage (Ch.6): DNS/egress blocked
- DB partial outage (Postgres): connection errors, read-only flip
- Model runtime (vLLM) crash / queue stall
- Cache layer disabled / stale returns (Ch.36)
- Tool/provider flake (rate limit, 429/5xx)
- Residency misroute (Ch.30)
- Safety guard failure (Ch.17/26)
- Billing pipeline lag (Ch.24)
- Audit pipeline backlog (Ch.31)
For each: expected blast radius, auto-mitigation, manual fallback, observability signals, exit criteria.
