# Chapter 33 — SIEM & Threat Detection Bridge

## Decision Summary
Integrate platform logs and signals into a **SIEM-compatible mapping** with a seed set of detections and response playbooks.
This bridges **Audit (Ch.31)**, **RBAC (Ch.23)**, **Prompt Firewall (Ch.26)**, **Billing (Ch.24)**, **Residency (Ch.30)**,
and **Backups/DR (Ch.15)** for unified security monitoring.

## Scope
- Normalization mapping (event fields → SIEM schema).
- Seed detections with response severity and references.
- Readiness gate + alerts + SOC runbooks.
- No agent/collector installation; documentation-only.

## Non-goals
- Managing external SIEM infrastructure.
- Real-time EDR/HIDS rollout.

## Ties
Ch.6 proxy, Ch.7 observability, Ch.8 secrets/IAM, Ch.9 compliance, Ch.10 CI/CD, Ch.12 cost, Ch.23 RBAC, Ch.24 billing,
Ch.25 exports, Ch.26 firewall, Ch.30 residency, Ch.31 audit.
