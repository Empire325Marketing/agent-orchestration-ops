# Usage Dispute Resolution

## Objective
Investigate and resolve billing disputes fairly and efficiently while maintaining accurate usage records.

## Dispute Categories

### 1. Usage Calculation Error
- Customer claims meter readings are incorrect
- Potential causes: aggregation bug, rate misconfiguration, double-counting

### 2. Unauthorized Usage
- Customer claims they didn't authorize the usage
- Potential causes: compromised API keys, malicious actor, account takeover

### 3. Service Quality Issue
- Customer claims poor service quality warrants billing adjustment
- Potential causes: high latency, errors, downtime during their usage

### 4. Pricing Disagreement
- Customer disputes the rates applied
- Potential causes: tier misconfiguration, contract terms misunderstanding

## Investigation Process

### Step 1: Intake and Triage (24h SLA)
1. Customer submits dispute via support ticket or billing portal
2. Collect basic information:
   - Tenant ID and billing period
   - Specific meter(s) in dispute  
   - Claimed vs. billed amounts
   - Supporting evidence (logs, screenshots)
3. Assign severity based on amount and customer tier

### Step 2: Data Collection (48h SLA)  
1. Export raw usage events for disputed period:
   ```sql
   SELECT event_time, route, tool, model, meter, quantity, trace_id
   FROM usage_events 
   WHERE tenant_id = '<tenant_id>'
     AND event_time BETWEEN '<period_start>' AND '<period_end>'
     AND meter = '<disputed_meter>'
   ORDER BY event_time;
   ```

2. Cross-reference with observability data:
   - API request logs matching trace_ids
   - Error rates and latency during period
   - Any system anomalies or outages

3. Validate aggregation calculations:
   ```sql
   -- Recreate rollup calculation
   SELECT 
     date_trunc('day', event_time)::date as day,
     meter,
     SUM(quantity) as calculated_total
   FROM usage_events
   WHERE tenant_id = '<tenant_id>' 
     AND event_time BETWEEN '<period_start>' AND '<period_end>'
   GROUP BY 1, 2
   ORDER BY 1, 2;
   ```

### Step 3: Root Cause Analysis (72h SLA)

**For Calculation Errors:**
- Compare raw events to rolled-up totals
- Check for timezone issues, duplicate events, missing events
- Verify pricing tier and rate application

**For Unauthorized Usage:**
- Review API key usage patterns and IP addresses  
- Check for unusual spikes or off-hours activity
- Validate authentication logs and session data

**For Service Quality:**
- Calculate actual error rates and latency percentiles
- Compare to SLA thresholds (Ch.13 readiness gates)
- Document any SLA breaches during disputed period

### Step 4: Resolution Decision

**If Customer is Correct:**
1. Calculate correct charges based on evidence
2. Generate credit for overbilled amount
3. Apply credit to account and update invoice
4. Document root cause and prevention measures

**If Billing is Correct:**
1. Prepare detailed explanation with supporting data
2. Offer education on usage optimization if appropriate
3. Consider goodwill credit for investigation inconvenience

**If Partial Adjustment Warranted:**
1. Calculate fair adjustment based on verified issues
2. Apply partial credit with clear reasoning
3. Document compromise solution

## Resolution Actions

### Credit Processing
```sql
-- Document adjustment in credits table
INSERT INTO credits (tenant_id, amount, reason, reference_id, created_by)
VALUES (
  '<tenant_id>',
  <credit_amount>,
  'Usage dispute resolution - <brief_description>',
  '<ticket_id>',
  '<resolver_id>'
);
```

### Invoice Correction
- Issue corrected invoice if amount is significant (>$10)
- For small amounts, apply credit to next invoice
- Update invoice status and add dispute resolution notes

### System Corrections
- Fix any identified bugs in metering or aggregation
- Update pricing configurations if incorrect
- Improve monitoring to catch similar issues early

## Customer Communication

### Initial Acknowledgment (within 4h)
```
Subject: Billing Dispute #{{ticket_id}} - Under Investigation

We've received your billing dispute for invoice {{invoice_id}} and are investigating.

Expected Resolution: {{business_days}} business days
Your Reference: {{ticket_id}}

We'll provide updates every 48 hours until resolved.
```

### Resolution Notice  
```
Subject: Billing Dispute #{{ticket_id}} - Resolved

Investigation Complete: {{resolution_summary}}

Action Taken: {{credit_amount > 0 ? "Credit applied" : "Billing confirmed accurate"}}
{{if credit_amount > 0}}Credit Amount: ${{credit_amount}}{{endif}}

Detailed explanation: {{detailed_findings}}

Thank you for bringing this to our attention.
```

## Escalation Criteria

**Immediate Escalation:**
- Dispute amount > $1,000
- Suspected data breach or security issue
- Customer threatens legal action
- Pattern of similar disputes from multiple customers

**Management Review Required:**
- Credit amount > $500
- System bug affecting multiple customers
- Customer requests executive escalation

## Prevention Measures

1. **Improved Monitoring:**
   - Alert on unusual usage spikes per tenant
   - Validate aggregation job accuracy daily
   - Monitor dispute frequency by meter/customer

2. **Better Documentation:**
   - Usage dashboard with drill-down capabilities
   - Clear pricing documentation and examples
   - Proactive usage alerts before overage

3. **Process Improvements:**
   - Automated anomaly detection in usage patterns
   - Self-service dispute submission portal
   - Faster data export tools for investigations

## DECISIONS.log Entry

```
<TIMESTAMP> | OPERATOR=<resolver> | ACTION=usage_dispute_resolved | TENANT=<tenant_id> | PERIOD=<yyyy-mm> | DISPUTED=<original_amount> | CREDITED=<credit_amount> | REASON=<category> | EXECUTOR=<team>
```

## SLA Commitments

| Customer Tier | Initial Response | Investigation | Resolution |
|---------------|------------------|---------------|------------|
| Enterprise | 4 hours | 48 hours | 72 hours |
| Pro | 8 hours | 72 hours | 5 business days |
| Free | 24 hours | 7 days | 14 days |

*SLA clock stops when waiting for customer response*
