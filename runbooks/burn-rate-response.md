# Runbook — Error Budget Burn Response
1) Confirm SLO and burn windows tripped (1h>2x → page; 6h>1x → warn).
2) Enter change freeze; enable brownout if configured; throttle risky routes.
3) If burn persists 30m: rollback last deploy; switch to secondary model/tool.
4) Exit criteria: burn<1x for 4h; record DECISIONS.log entry and postmortem link.