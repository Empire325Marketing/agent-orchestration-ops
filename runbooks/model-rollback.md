# Runbook — Model Rollback (Local)
1) Identify last known-good local model configuration and version gate.
2) Switch active config back to last good; record decision in DECISIONS.log.
3) Validate with smoke prompts; confirm SLOs return to baseline.
4) Open incident ticket with root cause notes; schedule postmortem.