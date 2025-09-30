# Cache Readiness Gate

Pass
- Hit rate ≥ 0.40 on canary traffic for 60 min
- No safety/PII cache violations
- Zero stale-beyond-TTL responses in sample probe
- Pre-warm list executed for top N routes

Fail
- Block promotion; run cache-warm & cache-busting runbooks; re-test
