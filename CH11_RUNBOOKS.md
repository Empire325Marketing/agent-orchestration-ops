# Chapter 11 — Runbooks

## Overview
This chapter provides a comprehensive collection of operational runbooks covering incident response, system management, model operations, compliance, and observability. Each runbook follows a step-by-step format for reliable execution during both normal operations and crisis situations.

## Existing Runbooks
The following runbooks were created in previous chapters and are linked here for reference:

### Model Operations (Existing)
- **[model-rollback.md](/srv/primarch/runbooks/model-rollback.md)** - Local model rollback procedures for incidents
- **[model-brownout.md](/srv/primarch/runbooks/model-brownout.md)** - Model brownout and overload response

### Observability (Existing)
- **[burn-rate-response.md](/srv/primarch/runbooks/burn-rate-response.md)** - Error budget burn response procedures
- **[trace-coverage-gap.md](/srv/primarch/runbooks/trace-coverage-gap.md)** - Trace coverage SLO remediation

### Security & IAM (Existing)
- **[break-glass.md](/srv/primarch/runbooks/break-glass.md)** - Emergency access procedures with dual approval
- **[secrets-rotation.md](/srv/primarch/runbooks/secrets-rotation.md)** - Vault secrets rotation procedures

### Tool & Network (Existing)
- **[tool-fallbacks.md](/srv/primarch/runbooks/tool-fallbacks.md)** - Tool fallback and circuit breaker procedures
- **[proxy-outage.md](/srv/primarch/runbooks/proxy-outage.md)** - Proxy outage and degradation response
- **[sandbox-escape.md](/srv/primarch/runbooks/sandbox-escape.md)** - Sandbox security breach response

### Compliance & Data (Existing)
- **[compliance-audit.md](/srv/primarch/runbooks/compliance-audit.md)** - Periodic compliance verification
- **[dsr.md](/srv/primarch/runbooks/dsr.md)** - Data subject request processing
- **[legal-hold.md](/srv/primarch/runbooks/legal-hold.md)** - Legal hold application and clearance
- **[delete-recruitment.md](/srv/primarch/runbooks/delete-recruitment.md)** - Recruitment record deletion
- **[delete-core-hr.md](/srv/primarch/runbooks/delete-core-hr.md)** - Core HR record deletion
- **[delete-payroll.md](/srv/primarch/runbooks/delete-payroll.md)** - Payroll/tax record deletion
- **[delete-i9.md](/srv/primarch/runbooks/delete-i9.md)** - I-9/right-to-work record deletion

## New Runbooks Created
The following runbooks are created in this chapter to complete operational coverage:

### Incident Management (New)
- **[incident.md](/srv/primarch/runbooks/incident.md)** - Incident response framework with severity levels
- **[overload.md](/srv/primarch/runbooks/overload.md)** - System overload and admission control
- **[load-shedding.md](/srv/primarch/runbooks/load-shedding.md)** - Feature load shedding procedures
- **[failover-dr.md](/srv/primarch/runbooks/failover-dr.md)** - Disaster recovery and failover

### Technical Operations (New)
- **[retry-backoff.md](/srv/primarch/runbooks/retry-backoff.md)** - Retry and backoff strategies
- **[cache-busting.md](/srv/primarch/runbooks/cache-busting.md)** - Cache invalidation procedures
- **[drift-bias.md](/srv/primarch/runbooks/drift-bias.md)** - Model drift and bias detection response

### Cost Management (New)
- **[cost-guardrails.md](/srv/primarch/runbooks/cost-guardrails.md)** - Cost overrun response and throttling

## Usage Guidelines
- Each runbook includes step-by-step procedures
- DECISIONS.log entries are required for significant actions
- Cross-references link to related procedures and policies
- Regular review and updates ensure procedures remain current