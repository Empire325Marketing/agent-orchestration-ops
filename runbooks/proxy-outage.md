# Runbook — Proxy Outage / Degraded
1) Detect via health checks or >5% error budget burn on egress calls.
2) Fallback: disable web research features; serve cached knowledge only.
3) Backoff: exponential jitter; test every 5 minutes; cap concurrency to 1.
4) Recovery: re-enable gradually (10% → 50% → 100%); monitor p95 latency and errors.
5) Log: DECISIONS.log entry with outage start/end timestamps.