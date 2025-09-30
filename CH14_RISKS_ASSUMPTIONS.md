# Chapter 14 — Risks & Assumptions

## Decision Summary
- **Living risk register**: Continuously updated catalog of identified risks
- **Risk categorization**: Six primary categories with structured scoring
- **Mitigation mapping**: Direct links between risks and operational runbooks
- **Review cadence**: Weekly triage, monthly deep-dive, quarterly posture assessment
- **Exception handling**: Formal process for temporary policy deviations

## Risk Categories

### Technical Risks
- Infrastructure failures and service outages
- API dependency failures and quota limits
- Database performance degradation and corruption
- Network connectivity and latency issues
- Security vulnerabilities and configuration drift

### Data Risks
- Data corruption and inconsistency
- Privacy breaches and PII exposure
- Data retention policy violations
- Backup and recovery failures
- Vector database synchronization issues

### Model Risks
- Model drift and performance degradation
- Bias amplification and fairness issues
- Model security and jailbreaking
- Inference latency and timeout issues
- Model version rollback complexity

### Compliance Risks
- Regulatory requirement violations (GDPR, AI Act)
- Audit trail gaps and data loss
- Legal hold implementation failures
- Data subject request processing delays
- Documentation and evidence insufficiency

### Operational Risks
- Incident response coordination failures
- Runbook accuracy and completeness gaps
- On-call coverage and escalation issues
- Change management process bypasses
- Monitoring blind spots and alert fatigue

### Cost Risks
- Budget overruns and cost anomalies
- Resource inefficiency and waste
- Tenant billing accuracy issues
- Infrastructure scaling cost spikes
- Third-party service cost increases

## Risk Scoring Framework

### Likelihood Scale (1-5)
- **1 - Very Low**: <5% probability in next 12 months
- **2 - Low**: 5-20% probability in next 12 months
- **3 - Medium**: 20-50% probability in next 12 months
- **4 - High**: 50-80% probability in next 12 months
- **5 - Very High**: >80% probability in next 12 months

### Impact Scale (1-5)
- **1 - Minimal**: Minor inconvenience, no service impact
- **2 - Low**: Limited service degradation, quick recovery
- **3 - Medium**: Moderate service impact, measurable user effect
- **4 - High**: Significant service disruption, business impact
- **5 - Critical**: Service unavailability, severe business/legal consequences

### Risk Score Calculation
`Risk Score = Likelihood × Impact`

### Priority Classification
- **Critical (20-25)**: Immediate action required
- **High (15-19)**: Action required within 30 days
- **Medium (8-14)**: Action required within 90 days
- **Low (4-7)**: Monitor and review quarterly
- **Minimal (1-3)**: Accept and monitor annually

## Review Cadence

### Weekly Risk Triage
- Review new risks and incidents from previous week
- Update risk scores based on recent events
- Prioritize mitigation efforts for critical/high risks
- Validate existing mitigation effectiveness

### Monthly Deep-Dive Review
- Comprehensive review of all active risks
- Assess mitigation progress and effectiveness
- Update risk register with new threats and changes
- Review and update runbook linkages

### Quarterly Risk Posture Assessment
- Strategic review of overall risk landscape
- Assess risk appetite and tolerance levels
- Review and update risk management processes
- Board/stakeholder reporting preparation

## Integration with Existing Framework

### Runbook Integration
- Every risk links to specific operational runbooks
- Runbooks tested as part of mitigation validation
- Incident response procedures include risk register updates
- Post-incident reviews identify new risks

### Observability Integration (Chapter 7)
- Risk indicators monitored through existing dashboards
- Alert thresholds aligned with risk tolerance
- Metric-based early warning systems for risk escalation
- Historical trend analysis for risk pattern identification

### Compliance Integration (Chapter 9)
- Regulatory risks tracked against compliance frameworks
- Risk assessments inform DPIA and AI Act documentation
- Audit requirements include risk management validation
- Legal hold failures tracked as compliance risks

## Assumptions Register

### Technical Assumptions
- PostgreSQL can scale to projected user load
- vLLM inference latency remains within SLA bounds
- Kong API Gateway handles expected throughput
- Network connectivity maintains 99.9% availability

### Business Assumptions
- User adoption follows projected growth curves
- Regulatory environment remains stable
- Budget allocations sufficient for projected scale
- Third-party service availability meets expectations

### Operational Assumptions
- 24/7 on-call coverage maintainable with current team
- Runbook procedures remain current and executable
- Incident response times meet stakeholder expectations
- Change management processes prevent major outages

## Cross-References
- Risk register: risks/register.md
- Mitigation mapping: risks/mitigations.md
- Review procedures: risks/review_cadence.md
- Exception handling: runbooks/risk-exception.md
- Incident response: runbooks/incident.md