# Chapter 21 — Customer Feedback & Support Loops

## Decision Summary
We establish a closed-loop system connecting customer signals to engineering action: intake → triage → SLA/OLA execution → analytics review → roadmap decisions → customer follow-up.

## Scope (MVP)
- Intake channels (in-product feedback, email, GitHub issues, Discord forms)
- Triage matrix (sev/prio rules) and SLA/OLA
- Ops playbook (when to escalate to incident Ch.11)
- Metrics/alerts (SLA, backlog, breach risk) via Prometheus (Ch.7)
- "Close the loop" comms & VoC summaries (feeds Ch.20 analytics & Ch.14 risks)

## Non-Goals
- Full CRM or ticketing deployment; we provide schema, docs, and metrics only.

## Integrations
- **Ch.7 Observability**: metrics + alerts
- **Ch.10 CI/CD**: readiness gates may block promotion if breach risk ↑
- **Ch.12 Cost**: throttle high-cost tickets (heavy workloads)
- **Ch.13 Readiness**: quality/safety thresholds drive severity
- **Ch.17 Safety**: jailbreaking/PII tickets route to safety runbooks
- **Ch.19 Go-Live**: on-call & comms alignment
- **Ch.20 Analytics**: VoC summaries in weekly reviews
