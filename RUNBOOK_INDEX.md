# Runbook Index

## Operations
- **[incident.md](/srv/primarch/runbooks/incident.md)** - Incident response framework with severity levels and communication protocols
- **[overload.md](/srv/primarch/runbooks/overload.md)** - System overload response, admission control, and queue management
- **[load-shedding.md](/srv/primarch/runbooks/load-shedding.md)** - Progressive feature disabling under load
- **[retry-backoff.md](/srv/primarch/runbooks/retry-backoff.md)** - Retry strategies and backoff algorithms with idempotency guidance
- **[failover-dr.md](/srv/primarch/runbooks/failover-dr.md)** - Disaster recovery and region failover procedures
- **[cache-busting.md](/srv/primarch/runbooks/cache-busting.md)** - Cache invalidation and cold-start mitigation
- **[cost-guardrails.md](/srv/primarch/runbooks/cost-guardrails.md)** - Budget management and cost overrun response

## Model Operations
- **[model-rollback.md](/srv/primarch/runbooks/model-rollback.md)** - Local model rollback procedures for incidents
- **[model-brownout.md](/srv/primarch/runbooks/model-brownout.md)** - Model performance degradation response
- **[drift-bias.md](/srv/primarch/runbooks/drift-bias.md)** - Model drift and bias detection with human-in-loop procedures

## Compliance & Security
- **[compliance-audit.md](/srv/primarch/runbooks/compliance-audit.md)** - Periodic compliance verification and audit procedures
- **[dsr.md](/srv/primarch/runbooks/dsr.md)** - Data subject request processing (access/erasure)
- **[legal-hold.md](/srv/primarch/runbooks/legal-hold.md)** - Legal hold application and clearance procedures
- **[delete-recruitment.md](/srv/primarch/runbooks/delete-recruitment.md)** - Recruitment record deletion procedures
- **[delete-core-hr.md](/srv/primarch/runbooks/delete-core-hr.md)** - Core HR record deletion procedures
- **[delete-payroll.md](/srv/primarch/runbooks/delete-payroll.md)** - Payroll and tax record deletion procedures
- **[delete-i9.md](/srv/primarch/runbooks/delete-i9.md)** - I-9/right-to-work record deletion procedures
- **[break-glass.md](/srv/primarch/runbooks/break-glass.md)** - Emergency access procedures with dual approval
- **[secrets-rotation.md](/srv/primarch/runbooks/secrets-rotation.md)** - Vault secrets rotation procedures
- **[sandbox-escape.md](/srv/primarch/runbooks/sandbox-escape.md)** - Sandbox security breach response

## Observability
- **[burn-rate-response.md](/srv/primarch/runbooks/burn-rate-response.md)** - Error budget burn rate response procedures
- **[trace-coverage-gap.md](/srv/primarch/runbooks/trace-coverage-gap.md)** - Trace coverage SLO remediation procedures

## Tools & Network
- **[tool-fallbacks.md](/srv/primarch/runbooks/tool-fallbacks.md)** - Tool fallback and circuit breaker procedures
- **[proxy-outage.md](/srv/primarch/runbooks/proxy-outage.md)** - Proxy outage and degradation response

## Quick Reference
- **Total Runbooks**: 25
- **Categories**: 5 (Operations, Model, Compliance/Security, Observability, Tools/Network)
- **Critical Procedures**: incident.md, model-rollback.md, break-glass.md, compliance-audit.md
- **High-Frequency**: overload.md, load-shedding.md, retry-backoff.md, cost-guardrails.md