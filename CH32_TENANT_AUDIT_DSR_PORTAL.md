# Chapter 32 — Tenant Audit & DSR Portal

## Decision Summary
Provide a **read-only, RBAC-scoped tenant portal** for (a) self-serve audit visibility and (b) streamlined Data Subject Requests (DSR).
Portal respects **data residency (Ch.30)**, uses **audit logs (Ch.31)**, **exports/offboarding (Ch.25)**, and enforces **RBAC (Ch.23)**.

## Scope
- Views: Audit trail, Usage/Billing glance (read-only), DSR center (request status, downloads).
- API contracts for read-only endpoints and DSR submission webhooks.
- Readiness gate, alerts, and runbooks (intake + fulfillment).
- No PII display beyond minimal metadata; exports delivered via signed URLs (Ch.25).

## Non-goals
- Live billing or payments; only summaries (Ch.24 source of truth).
- External identity provider wiring (still out-of-scope for MVP).
- Real UI build—this chapter defines specs, contracts, and ops only.

## Flows
1) **Tenant Audit View:** filters by date, family, status; links to trace (Ch.7).  
2) **DSR Intake:** owner/admin submits request → triaged → SLA clock starts.  
3) **DSR Fulfillment:** generate export via Ch.25 profiles → verify → deliver → close.

## SLAs (MVP)
- Acknowledgement ≤ 7 days; **Export ≤ 30 days**; **Deletion ≤ 45 days** (where applicable).  
- Transparency: every state transition is recorded in audit (Ch.31).

## Ties
Ch.6 proxy, Ch.7 observability, Ch.8 secrets/IAM, Ch.9 compliance, Ch.10 CI/CD, Ch.13 readiness, Ch.23 RBAC, Ch.24 billing, Ch.25 exports, Ch.30 residency, Ch.31 audit.
