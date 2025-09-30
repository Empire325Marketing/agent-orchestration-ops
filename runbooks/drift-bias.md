# Runbook — Model Drift and Bias Detection

## Detection Methods
- Statistical drift tests on feature distributions
- Performance degradation alerts from monitoring
- Bias metrics calculated across demographic groups
- Human feedback and escalation reports
- Automated A/B testing between model versions

## Threshold Configuration
- **Drift alert**: Statistical significance p < 0.05
- **Performance degradation**: >5% accuracy drop
- **Bias threshold**: Demographic parity ratio >1.2
- **Critical bias**: Any ratio >1.5 triggers immediate action

## Rollback Procedures
1) Suspend affected model immediately for critical issues
2) Activate human-only fallback procedures
3) Rollback to last known-good model version
4) Verify rollback effectiveness with test queries
5) Monitor performance recovery and bias metrics
6) Document rollback decision and rationale

## Retrain Decision Process
1) Analyze root cause of drift or bias
2) Assess data quality and representativeness
3) Determine if additional training data needed
4) Evaluate feature engineering requirements
5) Plan retraining with bias mitigation techniques
6) Set success criteria for retrained model

## Human-in-the-Loop Checklist

### Immediate Response
- [ ] Human reviewer assigned to validate model decisions
- [ ] Override mechanism activated for questionable outputs
- [ ] Escalation path established for edge cases
- [ ] Documentation of human interventions maintained

### Investigation Phase
- [ ] Sample recent decisions for human audit
- [ ] Identify patterns in problematic outputs
- [ ] Assess impact on affected user groups
- [ ] Gather stakeholder feedback on bias concerns

### Resolution Planning
- [ ] Define acceptance criteria for model restoration
- [ ] Plan testing strategy for model updates
- [ ] Establish ongoing monitoring enhancements
- [ ] Schedule regular bias review meetings

## Logging to DECISIONS
All drift and bias incidents require DECISIONS.log entries:
```
<TIMESTAMP> | OPERATOR=<name> | ACTION=drift_detected | MODEL=<id> | METRIC=<type> | THRESHOLD=<value> | RESPONSE=<rollback|retrain|monitor>
<TIMESTAMP> | OPERATOR=<name> | ACTION=bias_mitigation | MODEL=<id> | AFFECTED_GROUPS=<list> | MITIGATION=<description> | STATUS=<ongoing|resolved>
```

## Cross-References
- AI Act post-market monitoring: compliance/ai_act_post_market.md
- Model rollback procedures: runbooks/model-rollback.md
- Performance monitoring: observability framework Chapter 7