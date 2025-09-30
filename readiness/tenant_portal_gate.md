# Tenant Portal Readiness Gate

Pass
- RBAC checks enforced on all routes (Ch.23)
- Audit linkage coverage ≥ 0.95 (Ch.31)
- Residency filter active; cross-region = 0 (Ch.30)
- DSR backlog with due<7d = 0; SLA trackers enabled (Ch.9)
- Exports verified against rollups and contracts (Ch.24/16)

Fail
- Block promotion; execute runbooks dsr-intake.md / dsr-fulfillment.md; re-evaluate.
