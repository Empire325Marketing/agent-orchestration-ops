# Rollback Plan (Auto + Manual)

**Auto triggers (any sustained 30m):**
- p95 regression > +20% or error rate > 1.5× baseline
- safety_ok = false (jailbreak/PII)
- cost headroom < 20%
- readiness hook failure (compliance traces missing)

**Actions:**
1) Toggle off new flags (Ch.18) and revert traffic step.
2) CI/CD job "Rollback" (Ch.10) restores previous artifact (signed).
3) If DB changes involved, execute restore runbook (Ch.15) to last validated point; verify checksums.
4) Append DECISIONS.log with reason + metrics snapshot.
5) Open incident if customer impact observed; follow runbooks/incident.md.
