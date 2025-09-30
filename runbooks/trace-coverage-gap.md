# Runbook — Trace Coverage Below SLO
1) Identify missing instrumentation by service/endpoint.
2) Add SDK auto-instrumentation; ensure traceparent propagated through gateway and jobs.
3) Validate with canary traffic until coverage ≥0.95 for 1h.
4) Log remediation in DECISIONS.log.