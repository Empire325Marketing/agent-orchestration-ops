# Support Ops Playbook

## Intake → Triage → Execute
1) Classify ticket (bug/feature/question/safety) + route owner.
2) Assign severity via triage matrix.
3) Check related runbooks:
   - Incident (P1/P2): runbooks/incident.md
   - Safety incident: runbooks/safety-incident.md
   - Cost breach: runbooks/cost-guardrails.md
4) Track timestamps for SLA.
5) Customer comms: acknowledge, updates, resolution, survey.

## When to open an incident
- Any P1, or sustained P2 with growing blast radius.
- Safety hits (jailbreak/PII) → safety-incident.md.
- Readiness gates breached (Ch.13) → pause release.

## Close the loop
- Summarize in VoC weekly note (feedback/voice_of_customer.md)
- If user consented, notify on fix/ship.
