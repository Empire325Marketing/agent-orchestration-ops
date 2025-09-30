# Prompt Firewall Hotfix Procedures

## Objective
Rapidly deploy temporary firewall rule changes to address immediate security threats while maintaining system stability and user experience.

## Hotfix Triggers
- Active attack pattern detected
- New vulnerability disclosure affecting prompt security
- Safety evaluation failures in production
- Regulatory compliance requirement
- Zero-day exploit targeting AI systems

## Emergency Response Process

### Phase 1: Threat Assessment (< 15 minutes)
1. **Incident Classification**
   ```yaml
   incident_id: "PF-2025-001"
   severity: "critical|high|medium"
   threat_type: "jailbreak|injection|exfiltration|tool_abuse"
   affected_systems: ["frank_persona", "prompt_firewall"]
   estimated_impact: "high|medium|low"
   ```

2. **Evidence Collection**
   - Capture attack samples and patterns
   - Document affected user sessions
   - Identify common attack vectors
   - Assess current rule coverage gaps

3. **Impact Analysis**
   - Number of affected users/sessions
   - Potential data exposure risk
   - System availability impact
   - Compliance implications

### Phase 2: Temporary Rule Creation (< 30 minutes)
1. **Rule Development**
   ```yaml
   # Emergency firewall rule
   emergency_rules:
     - id: "emergency_001"
       type: "pattern_block"
       pattern: "specific_attack_pattern"
       action: "block"
       priority: "critical"
       expires: "2025-09-28T12:00:00Z"  # 24h default
       reason: "Emergency response to active attack"
   ```

2. **Rule Testing**
   ```bash
   # Quick validation on test data
   python firewall_tester.py --rule emergency_001 --samples attack_samples.txt
   
   # Safety check against legitimate traffic
   python firewall_tester.py --rule emergency_001 --samples legitimate_samples.txt
   ```

3. **False Positive Assessment**
   - Test against known good requests
   - Check impact on FRANK persona responses
   - Validate tool functionality preservation
   - Ensure user experience degradation is minimal

### Phase 3: Emergency Deployment (< 45 minutes)
1. **Hotfix Deployment**
   ```bash
   # Deploy emergency rule
   kubectl create configmap firewall-hotfix-001 --from-file=emergency_rules.yaml
   
   # Update firewall configuration
   kubectl patch deployment prompt-firewall -p '{"spec":{"template":{"spec":{"volumes":[{"name":"hotfix","configMap":{"name":"firewall-hotfix-001"}}]}}}}'
   
   # Restart firewall pods
   kubectl rollout restart deployment/prompt-firewall
   ```

2. **Verification**
   ```bash
   # Verify rule deployment
   kubectl logs -l app=prompt-firewall | grep "emergency_001"
   
   # Test attack mitigation
   curl -X POST /api/test-firewall -d '{"test_input": "attack_pattern"}'
   
   # Monitor block rates
   prometheus_query 'prompt_firewall_blocks_total{rule="emergency_001"}'
   ```

3. **Monitoring Setup**
   - Enable enhanced logging for emergency rule
   - Set up real-time alerts for rule effectiveness
   - Monitor false positive rates
   - Track user experience metrics

### Phase 4: Validation & Communication (< 60 minutes)
1. **Effectiveness Verification**
   - Confirm attack pattern is blocked
   - Verify legitimate traffic still flows
   - Check persona functionality intact
   - Validate tool integrations working

2. **Stakeholder Notification**
   ```
   Subject: Emergency Firewall Rule Deployed - Incident PF-2025-001
   
   Emergency firewall rule deployed to address [threat_type].
   
   Details:
   - Rule ID: emergency_001
   - Attack Pattern: [pattern_description]
   - Deployment Time: [timestamp]
   - Expiry: 24 hours (auto-removal)
   - Impact: Minimal - legitimate requests unaffected
   
   Monitoring: Real-time alerts active
   Next Steps: Permanent rule development in progress
   ```

3. **Documentation**
   - Log incident details and response timeline
   - Document rule effectiveness and side effects
   - Record lessons learned and improvements
   - Update incident response procedures

## Temporary Rule Management

### Rule Lifecycle
```yaml
emergency_rule_lifecycle:
  - created: "2025-09-27T08:00:00Z"
  - deployed: "2025-09-27T08:30:00Z"
  - validated: "2025-09-27T09:00:00Z"
  - expires: "2025-09-28T08:00:00Z"
  - permanent_rule_ready: "2025-09-28T06:00:00Z"
  - emergency_rule_removed: "2025-09-28T08:00:00Z"
```

### Auto-Expiry Configuration
```yaml
# Automatic rule expiry
rule_expiry:
  default_duration: "24h"
  max_duration: "72h"
  warning_before_expiry: "2h"
  auto_removal: true
  notification_required: true
```

### Extension Process
If temporary rule needs extension:
1. **Justification Required**: Document why permanent fix delayed
2. **Approval Needed**: Security team + incident commander
3. **Maximum Extension**: 48 additional hours
4. **Escalation**: If >72h total, escalate to executive team

## Permanent Rule Development

### Parallel Process
While emergency rule is active:
1. **Root Cause Analysis**: Understand why attack succeeded
2. **Comprehensive Solution**: Develop proper long-term fix
3. **Testing**: Full safety evaluation and consistency checks
4. **Integration**: Follow normal change control process

### Transition Planning
```bash
# Prepare permanent rule
python generate_permanent_rule.py --emergency-rule emergency_001

# Test permanent rule
python firewall_tester.py --rule permanent_001 --comprehensive-tests

# Deploy permanent rule
kubectl apply -f permanent-firewall-rules.yaml

# Remove emergency rule
kubectl delete configmap firewall-hotfix-001
```

## Rollback Procedures

### Emergency Rule Removal
```bash
# Immediate removal if causing issues
kubectl delete configmap firewall-hotfix-001
kubectl rollout restart deployment/prompt-firewall

# Verify removal
kubectl logs -l app=prompt-firewall | grep "Rule emergency_001 removed"
```

### System Restoration
If hotfix causes system issues:
1. **Immediate**: Remove emergency rule
2. **Assess**: Evaluate ongoing threat vs. system stability
3. **Alternative**: Deploy less restrictive emergency rule
4. **Monitor**: Watch for attack resumption
5. **Escalate**: If no safe middle ground, escalate to executive team

## Quality Assurance

### Pre-Deployment Checks
- [ ] Rule syntax validation passes
- [ ] Test data shows expected blocking behavior
- [ ] Legitimate traffic test passes
- [ ] No conflicts with existing rules
- [ ] Expiry time properly configured

### Post-Deployment Validation
- [ ] Attack pattern successfully blocked
- [ ] No false positive alerts triggered
- [ ] User experience metrics stable
- [ ] Persona consistency maintained
- [ ] System performance within normal range

## DECISIONS.log Entry

```
<TIMESTAMP> | OPERATOR=<incident_commander> | ACTION=firewall_emergency_rule_deployed | INCIDENT=<incident_id> | RULE=<rule_id> | THREAT=<threat_type> | EXPIRY=<expiry_time> | EXECUTOR=<system>
```

## Metrics & Reporting

### Key Metrics
- Time to detection: < 5 minutes
- Time to rule deployment: < 45 minutes
- Rule effectiveness: > 95% attack blocking
- False positive rate: < 1%
- System availability: > 99.9%

### Post-Incident Report
Required within 24 hours:
- Incident timeline and response actions
- Rule effectiveness analysis
- Impact on users and system performance
- Lessons learned and process improvements
- Permanent solution implementation plan
