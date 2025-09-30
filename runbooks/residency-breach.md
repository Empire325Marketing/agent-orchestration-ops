# Runbook — Residency Breach
1) Identify event(s) and data class (strict vs flexible).
2) Contain: halt offending route/tool via CI gate (Ch.10).
3) Verify no at-rest copies exist out-of-region; if any, quarantine & delete per Ch.9.
4) Remediate routing misconfig (residency/routing_policy.md); add test.
5) Post-incident: update matrices; append DECISIONS.log with scope and fix.
