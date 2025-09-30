# Runbook — Incident Response

## Severity Levels
- **SEV1 (Critical)**: Complete service outage, data loss, security breach
- **SEV2 (High)**: Major feature degradation, performance severely impacted
- **SEV3 (Medium)**: Minor feature issues, some users affected
- **SEV4 (Low)**: Cosmetic issues, minimal user impact

## Communications Tree
1) Incident Commander declares incident and severity
2) Notify on-call team via primary alerting channel
3) SEV1/SEV2: Escalate to management within 15 minutes
4) SEV1: Notify legal/compliance teams if data involved
5) Customer communication via status page for SEV1/SEV2

## Status Page Updates
- SEV1: Update within 5 minutes, every 15 minutes thereafter
- SEV2: Update within 15 minutes, every 30 minutes thereafter
- SEV3/SEV4: Update at incident start and resolution
- Include estimated resolution time when available

## Timeline Capture
1) Record incident start time and detection method
2) Log all investigative steps and findings
3) Document mitigation actions and their effectiveness
4) Note escalation points and decision rationale
5) Capture resolution time and root cause summary
6) Schedule postmortem within 48 hours for SEV1/SEV2
7) Update DECISIONS.log with incident reference and lessons learned