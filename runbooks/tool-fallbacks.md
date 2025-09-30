# Runbook — Tool Fallbacks & Circuit Breakers
1) Detect failure via error budget burn or 5xx streak (N≥3).
2) Engage client circuit breaker; route to declared fallback.
3) Record fallback decision (tool, reason, fallback_target) to DECISIONS.log and audit table.
4) Exit fallback after green health checks for 15 minutes.