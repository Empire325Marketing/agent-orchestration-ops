# Security Readiness Gate

Pass
- Log normalization coverage ≥ 0.95 (by traffic)
- Seed detections (≥10) enabled and evaluated in shadow
- Mean detection latency ≤ 60s; false-positive rate < 2% over 24h
- On-call SOC runbook references present; paging path verified

Fail
- Block promotion; execute SOC runbooks and re-evaluate.
