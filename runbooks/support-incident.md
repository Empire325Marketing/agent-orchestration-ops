# Support-Driven Incident (Bridge Playbook)
Trigger: P1, or P2 trending worse; safety hits; mass regressions.
Steps:
1) Open incident (runbooks/incident.md). Assign roles + comms.
2) Collect evidence (traces, metrics, tickets, repro).
3) Mitigation: feature flags, rollbacks (Ch.10 canary), brownout if needed.
4) Customer comms updates every {15–30} minutes until stable.
5) Postmortem (runbooks/postmortem.md). Add actions to backlog.
