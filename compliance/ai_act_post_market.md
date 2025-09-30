# EU AI Act Post-Market Monitoring Plan (Article 72)

## Scope and Classification
This plan covers high-risk AI systems for HR applications including automated recruitment screening and performance evaluation assistance. These systems fall under Annex III, Section 4(a) of the EU AI Act as AI systems intended for recruitment and selection of natural persons.

## Metrics Monitored

### Performance Metrics
- Model accuracy and precision across demographic groups
- False positive/negative rates by protected characteristics
- Decision consistency across similar candidate profiles
- Human override frequency and patterns

### Bias Detection Metrics
- Demographic parity across gender, age, ethnicity (where legally permissible to monitor)
- Equalized odds ratios between demographic groups
- Calibration differences across protected classes
- Disparate impact ratios (80% rule compliance)

### System Health Metrics
- Prediction confidence distributions
- Model drift indicators (data and concept drift)
- Feature importance stability over time
- Error pattern analysis by decision type

## Incident Classes and Thresholds

### Level 1 - Critical Incidents (Immediate Response)
- Bias ratio exceeding 1.25x for any protected group
- System accuracy dropping below 85% for core functions
- Data breach affecting AI training or decision data
- **Response Time**: Immediate notification, system suspension within 2 hours

### Level 2 - Major Incidents (24-48 Hour Response)
- Bias ratio between 1.15x-1.25x
- Accuracy degradation of 5-10% from baseline
- Significant model drift (>2 standard deviations)
- **Response Time**: Investigation within 24 hours, mitigation within 48 hours

### Level 3 - Minor Incidents (Weekly Review)
- Bias ratio between 1.05x-1.15x
- Minor accuracy fluctuations (<5%)
- Early drift warning indicators
- **Response Time**: Weekly review cycle, monthly trend analysis

## Reporting Timelines

### Competent Authority Notifications
- **Critical incidents**: Within 24 hours of detection
- **Major incidents**: Within 72 hours of detection
- **Quarterly reports**: Performance metrics and trend analysis
- **Annual report**: Comprehensive system assessment and improvements

### Internal Reporting
- **Daily**: Automated metric dashboards and alerts
- **Weekly**: Incident summary and trend review
- **Monthly**: Detailed bias and performance analysis
- **Quarterly**: Executive summary with regulatory compliance status

## Roles and Responsibilities

### AI Ethics Officer
- Overall monitoring program oversight
- Regulatory compliance coordination
- Incident escalation and external reporting

### Data Science Team
- Metric calculation and trend analysis
- Model performance monitoring
- Bias detection algorithm maintenance

### Legal Team
- Regulatory interpretation and guidance
- External authority communications
- Incident legal risk assessment

### HR Operations
- Business impact assessment
- Human oversight coordination
- Process improvement recommendations

## Review Cadence

### Continuous Monitoring
- Real-time bias detection alerts
- Daily performance metric tracking
- Automated drift detection systems

### Periodic Reviews
- **Weekly**: Metrics review and incident assessment
- **Monthly**: Comprehensive performance analysis
- **Quarterly**: Regulatory compliance review
- **Annually**: Complete system and process audit

## Log Retention
All monitoring data, incident reports, and compliance documentation retained per observability framework (Chapter 7) with minimum 5-year retention for regulatory compliance. Audit logs stored in tamper-evident format with cryptographic integrity protection.

## Rollback and Response Procedures
Upon detecting drift or bias breach:
1. Immediate system suspension for Level 1 incidents
2. Activate human-only fallback procedures per existing runbooks
3. Execute model rollback to last known-good version
4. Conduct root cause analysis per incident response procedures
5. Implement corrective measures before system re-activation
6. Document lessons learned and update monitoring thresholds

## Cross-Reference to Existing Runbooks
- Model rollback: `/srv/primarch/runbooks/model-rollback.md`
- Incident response: `/srv/primarch/runbooks/burn-rate-response.md`
- Brownout procedures: `/srv/primarch/runbooks/model-brownout.md`
- Compliance auditing: `/srv/primarch/runbooks/compliance-audit.md`