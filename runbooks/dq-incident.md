# Runbook — Data Quality Incident

## Trigger
- DQ alerts firing or failing gates in CI/CD (Ch.10) or Readiness (Ch.13).

## Steps
1) Declare incident; set severity based on blast radius.
2) Identify failing checks (which dataset/contract).
3) Contain: pause promotions; enable sandbox; stop backfills if needed.
4) Diagnose: schema drift? bad producer? malformed tool output?
5) Remediate: fix producer; backfill/repair; re-run checks.
6) Validate: all checks PASS; close incident; write DECISIONS.log entry.
