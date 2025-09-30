# Chaos Readiness Gate

Pass
- ≥3 distinct experiments executed in last 30 days
- All Pass criteria met with attached evidence (links to traces and metrics)
- No open Sev-1/2 incidents from chaos in last 14 days
- Error budget burn during experiments ≤ 1x baseline (Ch.7)

Fail
- Block promotion; run chaos-game-day and remediation, re-run experiments; append DECISIONS.
