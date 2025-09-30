# Tenant Offboarding Process

## Objective
Safely and completely remove tenant data and access while maintaining compliance, audit trails, and professional customer relationships.

## Trigger Events
- Customer cancellation request
- Non-payment after grace period
- Contract termination
- Compliance-required deletion
- Legal/court order

## Pre-Offboarding Checklist (T-14 days)

### Business Validation
- [ ] Confirm cancellation authority (account owner or authorized signatory)
- [ ] Review contract terms for notice period and obligations
- [ ] Check for outstanding invoices or credits
- [ ] Identify any active legal holds or litigation holds
- [ ] Verify no active support tickets requiring data access

### Technical Assessment
- [ ] Inventory all tenant data across systems
- [ ] Check data dependencies (shared projects, integrations)
- [ ] Estimate export size and complexity
- [ ] Confirm backup and disaster recovery implications
- [ ] Review any custom configurations or integrations

### Communication Plan
- [ ] Notify customer of offboarding timeline
- [ ] Offer data export if not already completed
- [ ] Coordinate with customer success team
- [ ] Prepare internal stakeholder notifications

## Phase 1: Data Export & Preservation (T-7 to T-1)

### 1.1 Mandatory Data Export
Even if customer hasn't requested export, generate one for legal protection:

```bash
# Trigger comprehensive export
POST /v1/exports
{
  "datasets": ["messages", "tool_calls", "embeddings", "support_tickets", "invoices"],
  "format": "jsonl",
  "date_range": {"start": "account_creation", "end": "now"},
  "pii_masking": "none",
  "encryption": {"method": "aes256"},
  "delivery": {"method": "internal_retention"},
  "retention_purpose": "legal_compliance"
}
```

### 1.2 Verification & Storage
- [ ] Complete verification per export-verify.md runbook
- [ ] Store encrypted export in long-term retention system
- [ ] Generate retention schedule per legal requirements (Ch.9)
- [ ] Document export location in tenant record

### 1.3 Customer Notification
```
Subject: Account Closure - Final Data Export Available

Your account will be closed on {{closure_date}}. 

A final export of your data is available for download:
- Export ID: {{export_id}}
- Download: {{download_url}}
- Expires: {{expiry_date}}

This is your last opportunity to download your data.
After {{closure_date}}, data will be deleted per our retention policy.

Questions? Contact support@primarch.ai
```

## Phase 2: Access Disable (T-1 to T-0)

### 2.1 Freeze Account State
```sql
-- Mark tenant for deletion
UPDATE tenants 
SET status = 'offboarding',
    deletion_scheduled = '{{deletion_date}}',
    modified_at = now()
WHERE tenant_id = '{{tenant_id}}';

-- Disable new usage
UPDATE tenant_prices
SET tier = 'disabled'
WHERE tenant_id = '{{tenant_id}}';
```

### 2.2 Revoke Access
- [ ] Revoke all API keys and tokens (Ch.8 Vault)
- [ ] Disable user authentication for tenant users
- [ ] Remove from authorization systems (Ch.23 RBAC)
- [ ] Block billing and usage events
- [ ] Disable webhook endpoints

### 2.3 Service Dependencies
- [ ] Stop scheduled jobs and workflows
- [ ] Remove from monitoring and alerting
- [ ] Disable support ticket creation
- [ ] Cancel any recurring billing

## Phase 3: Billing Close-out (T-0 to T+7)

### 3.1 Final Invoice Generation
```sql
-- Generate final invoice for partial month
INSERT INTO invoices (
  invoice_id,
  tenant_id, 
  period_start,
  period_end,
  subtotal,
  credits,
  total,
  status,
  notes
) VALUES (
  'FINAL-{{tenant_id}}-{{date}}',
  '{{tenant_id}}',
  '{{period_start}}',
  now(),
  {{calculated_charges}},
  {{final_credits}},
  {{final_total}},
  'sent',
  'Final invoice - Account closure'
);
```

### 3.2 Payment Collection
- [ ] Process final payment if amount due
- [ ] Issue refund if credit balance exists
- [ ] Update accounting systems
- [ ] Close billing disputes if any
- [ ] Generate final tax documents

### 3.3 Financial Reconciliation
- [ ] Verify all usage metered and billed
- [ ] Confirm no outstanding credits or charges
- [ ] Archive billing records per requirements
- [ ] Update revenue recognition

## Phase 4: Data Deletion Schedule (T+7 to T+retention)

### 4.1 Retention Classification
Determine retention periods per Ch.9 compliance:

- **User Data**: Delete immediately after export confirmation
- **Business Records**: 7 years (invoices, contracts, support)
- **Operational Logs**: 13 months (access logs, usage events)
- **Legal Hold**: Indefinite until hold lifted

### 4.2 Staged Deletion
```sql
-- Schedule deletions by data class
INSERT INTO deletion_schedule (
  tenant_id,
  data_category,
  table_name,
  scheduled_date,
  retention_reason
) VALUES 
('{{tenant_id}}', 'user_data', 'messages', now() + interval '7 days', 'export_confirmed'),
('{{tenant_id}}', 'user_data', 'tool_calls', now() + interval '7 days', 'export_confirmed'),
('{{tenant_id}}', 'business_records', 'invoices', now() + interval '7 years', 'financial_compliance'),
('{{tenant_id}}', 'operational_logs', 'usage_events', now() + interval '13 months', 'audit_compliance');
```

### 4.3 Deletion Verification
- [ ] Confirm customer received and verified export
- [ ] Check no legal holds prevent deletion
- [ ] Validate retention schedule compliance
- [ ] Get deletion approval from legal/compliance

## Phase 5: Secure Deletion (Per Schedule)

### 5.1 Data Destruction
```sql
-- Secure deletion with verification
BEGIN;

-- Delete user data (immediate)
DELETE FROM messages WHERE tenant_id = '{{tenant_id}}';
DELETE FROM tool_calls WHERE tenant_id = '{{tenant_id}}';
DELETE FROM embeddings WHERE tenant_id = '{{tenant_id}}';
DELETE FROM attachments WHERE tenant_id = '{{tenant_id}}';

-- Verify deletion
SELECT 
  'messages' as table_name,
  COUNT(*) as remaining_rows
FROM messages WHERE tenant_id = '{{tenant_id}}'
UNION ALL
SELECT 'tool_calls', COUNT(*) FROM tool_calls WHERE tenant_id = '{{tenant_id}}'
UNION ALL  
SELECT 'embeddings', COUNT(*) FROM embeddings WHERE tenant_id = '{{tenant_id}}';

-- Should return all zeros

COMMIT;
```

### 5.2 Cleanup Operations
- [ ] Remove from backup systems
- [ ] Clear application caches
- [ ] Delete file storage objects
- [ ] Purge CDN and edge caches
- [ ] Remove monitoring configurations

### 5.3 Verification & Audit
- [ ] Confirm zero rows in primary tables
- [ ] Verify backup exclusions
- [ ] Check no orphaned references
- [ ] Generate deletion certificate
- [ ] Update compliance tracking

## Phase 6: Final Documentation (Completion)

### 6.1 Completion Verification
```sql
-- Final verification query
SELECT 
  table_name,
  COUNT(*) as remaining_records
FROM information_schema.tables t
CROSS JOIN LATERAL (
  SELECT COUNT(*) 
  FROM pg_class c 
  WHERE c.relname = t.table_name
    AND EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = t.table_name 
        AND column_name = 'tenant_id'
    )
) 
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
  AND table_name NOT LIKE '%_archive'
GROUP BY table_name
HAVING COUNT(*) > 0;
-- Should return no rows
```

### 6.2 Final DECISIONS.log Entry
```
<TIMESTAMP> | OPERATOR=<offboarding_lead> | ACTION=tenant_offboarding_complete | TENANT=<tenant_id> | EXPORT_ID=<export_id> | DELETION_DATE=<deletion_date> | DATA_RETAINED=<retention_summary> | EXECUTOR=<system>
```

### 6.3 Stakeholder Notification
```
Subject: Tenant Offboarding Complete - {{tenant_id}}

Tenant offboarding completed successfully.

Timeline:
- Export Generated: {{export_date}}
- Access Disabled: {{disable_date}}  
- Billing Closed: {{billing_close_date}}
- Data Deleted: {{deletion_date}}

Retained Data:
- Business records until {{business_retention_date}}
- Audit logs until {{audit_retention_date}}

All user data has been securely deleted.
Export archived for compliance: {{export_archive_ref}}

Completed by: {{offboarding_lead}}
```

## Emergency Procedures

### Immediate Deletion Required
1. **Court Order**: Follow legal directive exactly
2. **Security Breach**: Isolate and assess scope
3. **GDPR Right to Erasure**: 30-day compliance window
4. **Customer Safety**: Immediate action required

### Rollback Procedures
If offboarding must be reversed:
1. Stop any scheduled deletions
2. Restore from export if data already deleted
3. Re-enable access systems
4. Restart billing and monitoring
5. Notify customer of restoration

## Quality Assurance

### Required Approvals
- [ ] Business owner confirms closure authority
- [ ] Legal/compliance approves retention schedule
- [ ] Finance confirms billing close-out
- [ ] Engineering validates technical deletion
- [ ] Security reviews access revocation

### Audit Requirements
- Complete audit trail in DECISIONS.log
- Export verification and storage confirmation  
- Deletion certificates with timestamps
- Retention schedule compliance documentation
- Customer communication records

## SLA Commitments

| Phase | Timeline | Responsibility |
|-------|----------|----------------|
| Pre-offboarding | T-14 to T-7 | Customer Success |
| Export & Verification | T-7 to T-1 | Engineering |
| Access Disable | T-1 to T-0 | Platform Team |
| Billing Close-out | T-0 to T+7 | Finance |
| Data Deletion | Per Schedule | Engineering |

**Total Duration**: 14-21 days (standard), expedited available for legal/security requirements.
