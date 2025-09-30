# Canary Rollout and Rollback Rules

## Promotion Rules

### Traffic Progression
1. **Initial canary**: 10% traffic for 30 minutes
2. **First expansion**: 25% traffic for 15 minutes
3. **Second expansion**: 50% traffic for 15 minutes
4. **Full rollout**: 100% traffic

### Auto-Promotion Criteria (All Must Be Met)
- **Error rate**: <1.5× baseline for current traffic level
- **P95 latency**: <20% regression from baseline
- **Error budget burn**: <2× normal rate over 30-minute window
- **Custom metrics**: No critical business metric degradation
- **Cost compliance**: No budget breach alerts (Chapter 12 integration)

### Promotion Decision Logic
```yaml
promotion_criteria:
  error_rate_threshold: 1.5  # 1.5x baseline
  latency_regression_threshold: 0.20  # 20% increase
  burn_rate_threshold: 2.0  # 2x normal burn
  observation_window_minutes: 30
  confidence_level: 0.95
```

## Rollback Triggers (Any One Triggers Immediate Rollback)

### Critical Rollback Conditions
- **Error budget burn >2× baseline** for 30 consecutive minutes
- **P95 latency regression >20%** sustained for 15 minutes
- **Error rate >1.5× baseline** for any traffic level
- **Budget breach alert** from cost monitoring system
- **Manual rollback** initiated by operator

### Secondary Rollback Conditions
- **Dependency failure**: Critical external service unavailable
- **Resource exhaustion**: Memory/CPU above 90% for 10 minutes
- **Security alert**: Critical vulnerability detected in deployment
- **Data integrity**: Database consistency check failures

## Automated Rollback Procedure

### Immediate Actions (Automated)
1. **Traffic reduction**: Immediately reduce canary traffic to 0%
2. **Health verification**: Confirm baseline version stable
3. **Alert generation**: Notify ops team of rollback action
4. **DECISIONS.log entry**: Record rollback with trigger reason

### Rollback Steps
1. **Phase 1 (0-2 minutes)**
   - Stop all traffic to canary version
   - Verify baseline version handling full load
   - Generate immediate operator alert

2. **Phase 2 (2-5 minutes)**
   - Scale down canary infrastructure
   - Preserve canary logs for investigation
   - Confirm all metrics returning to baseline

3. **Phase 3 (5-10 minutes)**
   - Complete infrastructure cleanup
   - Generate rollback summary report
   - Schedule post-incident review

### Rollback Verification
- **Traffic routing**: 100% to baseline version confirmed
- **Metric recovery**: All SLOs returning to green within 10 minutes
- **No data loss**: Database consistency verified
- **Service availability**: All endpoints responding normally

## Manual Rollback Procedures

### Operator-Initiated Rollback
- **Authentication**: Vault-based operator credentials required
- **Approval**: Single operator sufficient for emergency
- **Documentation**: Reason required in rollback command
- **Audit trail**: All actions logged to DECISIONS.log

### Emergency Rollback Commands
```bash
# Emergency rollback (immediate)
primarch rollback --reason="critical-issue" --immediate

# Staged rollback (gradual traffic reduction)
primarch rollback --reason="performance-degradation" --staged

# Rollback with investigation hold
primarch rollback --reason="security-alert" --preserve-canary
```

## DECISIONS.log Integration

### Automatic Logging (All Deployment Actions)
```
<TIMESTAMP> | OPERATOR=system | ACTION=canary_deploy | VERSION=<tag> | TRAFFIC=10% | STATUS=started | EXECUTOR=cicd-pipeline
<TIMESTAMP> | OPERATOR=system | ACTION=canary_promote | VERSION=<tag> | TRAFFIC=25% | METRICS=slo_green | EXECUTOR=cicd-pipeline
<TIMESTAMP> | OPERATOR=system | ACTION=canary_rollback | VERSION=<tag> | TRIGGER=error_rate_spike | METRICS=<details> | EXECUTOR=cicd-pipeline
<TIMESTAMP> | OPERATOR=<name> | ACTION=manual_rollback | VERSION=<tag> | REASON=<description> | EXECUTOR=operator
```

### Required Log Fields
- **VERSION**: Git commit SHA or semantic version
- **TRIGGER**: Specific metric or condition that caused action
- **METRICS**: Relevant metric values at time of decision
- **TRAFFIC**: Percentage of traffic at time of action

## Monitoring Integration

### Chapter 7 Observability Hooks
- **SLO burn rate monitoring**: Real-time calculation during canary
- **Custom dashboard**: Canary-specific metrics overlay
- **Alert routing**: Canary failures routed to ops team immediately
- **Trace sampling**: Increased sampling during canary period

### Cost Monitoring (Chapter 12)
- **Budget monitoring**: Enhanced during deployment window
- **Anomaly detection**: Deployment-triggered cost spikes
- **Emergency throttling**: Cost-based rollback triggers
- **Usage forecasting**: Predict full rollout cost impact

## Post-Rollback Procedures

### Immediate Investigation
1. **Log collection**: Preserve all canary logs and metrics
2. **Root cause analysis**: Identify deployment failure cause
3. **Impact assessment**: Measure user and system impact
4. **Communication**: Update status page and stakeholders

### Follow-up Actions
- **Fix development**: Address identified issues
- **Test enhancement**: Add tests to prevent recurrence
- **Process improvement**: Update deployment procedures
- **Documentation**: Update runbooks with lessons learned

## Cross-References
- Pipeline definitions: cicd/pipelines.md
- Observability framework: Chapter 7 monitoring
- Cost monitoring: Chapter 12 cost guardrails
- Emergency procedures: Chapter 8 break-glass
- Incident response: runbooks/incident.md