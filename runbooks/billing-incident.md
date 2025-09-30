# Billing Incident Response

## Scope
Handle billing system failures, payment processing issues, and billing disputes that affect service availability or revenue.

## Types of Incidents

### 1. Payment Processing Failure
**Trigger:** Payment gateway down, high failure rates, card processing issues

**Immediate Actions:**
1. Check payment processor status (Stripe, etc.)
2. Verify API keys and webhook endpoints
3. Switch to backup payment processor if available
4. Place affected accounts in grace period (24-48h)

**Containment:**
1. Stop automated service suspensions
2. Enable manual payment acceptance
3. Notify affected customers via email/dashboard
4. Document all manual overrides

### 2. Usage Metering Failure
**Trigger:** Missing rollups, incorrect calculations, data pipeline failure

**Immediate Actions:**
1. Stop invoice generation until data integrity confirmed
2. Check usage_events ingestion (last event timestamp)
3. Verify aggregation job status and logs
4. Validate data consistency (spot check known tenants)

**Containment:**
1. Backfill missing usage data from raw events
2. Recalculate affected invoices
3. Hold invoice delivery until validation complete

### 3. Billing System Outage  
**Trigger:** API down, database unreachable, critical service failure

**Immediate Actions:**
1. Check system health dashboards
2. Verify database connectivity and replication lag
3. Scale up billing service replicas
4. Enable read-only mode if writes are failing

**Containment:**
1. Queue critical operations (payments, suspensions)
2. Use cached pricing data if database unavailable
3. Manual failover to backup region if needed

### 4. Overbilling / Underbilling
**Trigger:** Customer complaint, anomaly detection, audit finding

**Immediate Actions:**
1. Stop further billing for affected meter/tenant
2. Pull raw usage data for the disputed period
3. Recalculate charges using correct rates
4. Generate adjustment invoice or credit

## Escalation Matrix

| Incident Type | Severity | Response Time | Escalation |
|---------------|----------|---------------|------------|
| Payment processor down | P1 | 15 min | Finance + Engineering |
| Usage data corruption | P1 | 30 min | Engineering + Legal |
| Single tenant overbilled | P2 | 1 hour | Customer Success |
| Billing dashboard down | P3 | 4 hours | Engineering |

## Grace Period Policy

### Pro Tier
- Payment failure: 7 days grace period
- Usage overage: Throttle at 120% of cap, block at 150%
- Past due: Send reminder at 7, 14, 21 days

### Enterprise Tier  
- Payment failure: 14 days grace period
- Usage overage: No automatic limits (manual review)
- Past due: Account manager contact at 14, 30 days

### Free Tier
- Usage overage: Hard block at 100% of cap
- No payment processing (upgrade required)

## Communication Templates

### Payment Failure Notice
```
Subject: Payment Issue - Account #{{tenant_id}}

We encountered an issue processing your payment for invoice {{invoice_id}}. 

Your service will continue uninterrupted for the next {{grace_days}} days while we resolve this.

Please update your payment method at: {{billing_portal_url}}

Contact billing@primarch.ai with questions.
```

### Billing Error Acknowledgment
```
Subject: Billing Adjustment - Invoice #{{invoice_id}}

We've identified and corrected a billing error on your account.

Correction: {{adjustment_description}}
Credit Applied: ${{credit_amount}}
Revised Total: ${{corrected_total}}

Updated invoice attached. Thank you for your patience.
```

## Recovery Actions

1. **Restore Service:** Remove suspension flags, clear rate limits
2. **Data Reconciliation:** Backfill usage events, recalculate rollups
3. **Financial Reconciliation:** Issue credits, generate corrected invoices
4. **Customer Communication:** Proactive outreach, service credits for impact
5. **System Health:** Verify all billing pipelines operational

## Retry and Backoff Policy

- Payment retries: 3 attempts over 48 hours (0h, 6h, 24h, 48h)
- API retries: Exponential backoff starting at 1s, max 60s
- Failed webhooks: Retry up to 7 days with increasing intervals
- Usage aggregation: Rerun failed jobs every 2 hours for 48 hours

## Service Downgrade Process

When payment cannot be collected after grace period:

1. **Warning Phase (7 days before):** Email + dashboard notification
2. **Soft Limit (Grace expires):** Rate limit to 10% of normal capacity  
3. **Hard Limit (Grace + 3 days):** Block new API requests
4. **Suspension (Grace + 7 days):** Full account suspension
5. **Data Retention:** 90 days before permanent deletion

## DECISIONS.log Entry

```
<TIMESTAMP> | OPERATOR=<responder> | ACTION=billing_incident | TYPE=<incident_type> | TENANTS=<count> | IMPACT=<revenue/service> | RESOLUTION=<summary> | CREDITS=<amount> | EXECUTOR=<team>
```

## Post-Incident

1. Root cause analysis within 48 hours
2. Update monitoring/alerting based on lessons learned  
3. Customer follow-up for service credits if warranted
4. Process improvements to prevent recurrence
