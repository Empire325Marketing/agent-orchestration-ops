# Risk Review Cadence

## Weekly Risk Triage

### Schedule
- **Day**: Every Tuesday, 10:00 AM UTC
- **Duration**: 30 minutes
- **Attendees**: Risk owners, on-call lead, security lead
- **Chair**: Rotating between risk category owners

### Agenda
1. **New Risk Identification** (5 minutes)
   - Review incidents from previous week
   - Identify emerging risks or risk pattern changes
   - Add new risks to register with initial scoring

2. **Critical/High Risk Review** (15 minutes)
   - Review all risks with score ≥15
   - Assess mitigation progress and effectiveness
   - Update risk scores based on recent events
   - Escalate risks requiring immediate attention

3. **Incident-Driven Updates** (5 minutes)
   - Update existing risks based on recent incidents
   - Validate runbook effectiveness during incidents
   - Identify gaps in current mitigation strategies

4. **Action Item Review** (5 minutes)
   - Review previous week's action items
   - Assign new action items with owners and due dates
   - Update risk status and mitigation progress

### Weekly Outputs
- Updated risk scores in register
- New risks added to register
- Action items with owners and due dates
- Escalation of critical issues to monthly review

### DECISIONS.log Entries
Weekly triage sessions require DECISIONS.log entries:
```
<TIMESTAMP> | OPERATOR=<chair> | ACTION=weekly_risk_triage | NEW_RISKS=<count> | SCORE_UPDATES=<count> | ESCALATIONS=<count> | EXECUTOR=risk_management
```

## Monthly Deep-Dive Review

### Schedule
- **Day**: First Wednesday of each month, 14:00 UTC
- **Duration**: 2 hours
- **Attendees**: All risk owners, department leads, security team, compliance officer
- **Chair**: Chief Technology Officer or designated risk manager

### Agenda
1. **Risk Register Comprehensive Review** (45 minutes)
   - Review all active risks in detail
   - Assess likelihood and impact score accuracy
   - Validate risk categorization and ownership
   - Review mitigation strategy effectiveness

2. **Runbook Validation and Testing** (30 minutes)
   - Review runbook linkages and accuracy
   - Schedule or conduct runbook testing
   - Identify runbook gaps or improvement needs
   - Update runbook references based on recent changes

3. **Trend Analysis and Pattern Recognition** (30 minutes)
   - Analyze risk score trends over time
   - Identify recurring risk patterns
   - Assess overall risk posture changes
   - Review external threat landscape changes

4. **Mitigation Strategy Updates** (15 minutes)
   - Update mitigation strategies based on learnings
   - Allocate resources for risk reduction initiatives
   - Set priorities for upcoming month
   - Review budget implications of risk mitigations

### Monthly Outputs
- Comprehensive risk register update
- Runbook testing schedule and results
- Risk trend analysis report
- Resource allocation decisions for risk mitigation
- Updated risk mitigation strategies

### DECISIONS.log Entries
Monthly reviews require detailed DECISIONS.log entries:
```
<TIMESTAMP> | OPERATOR=<chair> | ACTION=monthly_risk_review | TOTAL_RISKS=<count> | RUNBOOKS_TESTED=<count> | MITIGATIONS_UPDATED=<count> | BUDGET_ALLOCATED=<amount> | EXECUTOR=risk_management
```

## Quarterly Risk Posture Assessment

### Schedule
- **Day**: Second week of each quarter (January, April, July, October)
- **Duration**: Half day (4 hours)
- **Attendees**: Executive team, all department heads, risk owners, external advisors
- **Chair**: Chief Executive Officer or Chief Risk Officer

### Agenda
1. **Strategic Risk Landscape Review** (60 minutes)
   - Assess changes in business environment
   - Review regulatory and compliance landscape
   - Analyze competitive and market risks
   - Update strategic assumptions and dependencies

2. **Risk Appetite and Tolerance Assessment** (60 minutes)
   - Review current risk appetite statements
   - Assess risk tolerance levels across categories
   - Update risk scoring thresholds if needed
   - Align risk acceptance with business objectives

3. **Risk Management Process Evaluation** (60 minutes)
   - Review effectiveness of risk management processes
   - Assess adequacy of current mitigation strategies
   - Evaluate resource allocation for risk management
   - Identify process improvements and optimizations

4. **Board/Stakeholder Reporting Preparation** (60 minutes)
   - Prepare quarterly risk report for stakeholders
   - Summarize key risk trends and mitigations
   - Document risk-related decisions and rationale
   - Plan communication strategy for risk updates

### Quarterly Outputs
- Updated risk appetite and tolerance statements
- Strategic risk assessment report
- Risk management process improvements
- Stakeholder communication plan
- Budget allocation for risk initiatives

### DECISIONS.log Entries
Quarterly assessments require strategic DECISIONS.log entries:
```
<TIMESTAMP> | OPERATOR=<chair> | ACTION=quarterly_risk_assessment | RISK_APPETITE=<updated/unchanged> | TOLERANCE_CHANGES=<count> | STRATEGIC_RISKS=<count> | PROCESS_UPDATES=<count> | EXECUTOR=executive_team
```

## DECISIONS.log Integration

### Standard Entry Format
All risk management activities must log entries using this format:
```
<ISO8601_TIMESTAMP> | OPERATOR=<person_responsible> | ACTION=<activity_type> | <activity_specific_fields> | EXECUTOR=<team_or_system>
```

### Activity Types
- `weekly_risk_triage` - Weekly review sessions
- `monthly_risk_review` - Monthly deep-dive reviews
- `quarterly_risk_assessment` - Quarterly strategic assessments
- `risk_escalation` - Emergency risk escalations
- `risk_mitigation_update` - Changes to mitigation strategies
- `runbook_test` - Runbook validation and testing
- `risk_exception_request` - Temporary policy exception requests
- `risk_exception_approval` - Exception approvals and rejections

### Required Fields by Activity
**Weekly Triage:**
- `NEW_RISKS` - Number of new risks identified
- `SCORE_UPDATES` - Number of risk score changes
- `ESCALATIONS` - Number of risks escalated to monthly review

**Monthly Review:**
- `TOTAL_RISKS` - Total active risks in register
- `RUNBOOKS_TESTED` - Number of runbooks validated
- `MITIGATIONS_UPDATED` - Number of mitigation strategy changes
- `BUDGET_ALLOCATED` - Financial resources committed

**Quarterly Assessment:**
- `RISK_APPETITE` - Changes to risk appetite (updated/unchanged)
- `TOLERANCE_CHANGES` - Number of tolerance threshold changes
- `STRATEGIC_RISKS` - Number of strategic risks identified
- `PROCESS_UPDATES` - Number of process improvements

### Audit Trail Requirements
- All risk-related decisions must be logged
- Entries must be made within 24 hours of the activity
- Regular audit of DECISIONS.log completeness
- Retention per compliance requirements (Chapter 9)

## Emergency Risk Escalation

### Immediate Escalation Triggers
- New critical risk identified (score ≥20)
- Existing risk severity increase to critical level
- Multiple related risks manifesting simultaneously
- Risk mitigation failure during incident

### Emergency Response Process
1. **Immediate Assessment** (within 1 hour)
   - Assess risk scope and immediate impact
   - Activate relevant incident response procedures
   - Notify key stakeholders and risk owners

2. **Emergency Mitigation** (within 4 hours)
   - Implement immediate risk reduction measures
   - Activate emergency runbooks and procedures
   - Coordinate with incident response team

3. **Follow-up Actions** (within 24 hours)
   - Update risk register with new information
   - Schedule emergency review session if needed
   - Document lessons learned and process improvements

### Emergency DECISIONS.log Entries
```
<TIMESTAMP> | OPERATOR=<responder> | ACTION=emergency_risk_escalation | RISK_ID=<identifier> | SEVERITY=critical | MITIGATION=<immediate_actions> | EXECUTOR=incident_response
```

## Cross-References
- Risk register: risks/register.md
- Risk mitigation mapping: risks/mitigations.md
- Risk categories: CH14_RISKS_ASSUMPTIONS.md
- Exception procedures: runbooks/risk-exception.md
- Incident response: runbooks/incident.md
- Compliance audit: runbooks/compliance-audit.md