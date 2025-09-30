# Export Verification Procedures

## Objective
Ensure exported data integrity, completeness, and compliance before delivery to customers.

## Verification Phases

### Phase 1: Hash Verification (Required)

**Process:**
1. Calculate SHA256 for each exported file
2. Compare against manifest checksums
3. Verify manifest itself is not corrupted

**Commands:**
```bash
# Verify file hashes
for file in ${export_dir}/*.{jsonl,parquet,csv}*; do
  calculated=$(sha256sum "$file" | cut -d' ' -f1)
  expected=$(jq -r ".files[] | select(.path == \"$(basename $file)\") | .sha256" manifest.json)
  if [ "$calculated" != "$expected" ]; then
    echo "HASH_MISMATCH: $file"
    exit 1
  fi
done

# Verify manifest integrity
manifest_hash=$(sha256sum manifest.json | cut -d' ' -f1)
echo "Manifest SHA256: $manifest_hash"
```

**Failure Response:**
- Regenerate corrupted files
- Update manifest with new hashes
- Restart verification process
- Log incident for root cause analysis

### Phase 2: Row Count Validation (Required)

**Process:**
1. Count rows in each exported file
2. Compare with manifest totals
3. Cross-reference with usage rollups

**Validation Queries:**
```sql
-- Compare export counts with usage rollups
WITH export_counts AS (
  SELECT 'messages' as dataset, {{messages_row_count}} as exported_rows
  UNION ALL
  SELECT 'tool_calls', {{tool_calls_row_count}}
  UNION ALL
  SELECT 'support_tickets', {{tickets_row_count}}
),
rollup_counts AS (
  SELECT 
    meter as dataset,
    SUM(quantity) as rollup_rows
  FROM usage_rollups_daily
  WHERE tenant_id = '{{tenant_id}}'
    AND date BETWEEN '{{export_start_date}}' AND '{{export_end_date}}'
    AND meter IN ('messages_stored', 'tool_calls_made', 'tickets_created')
  GROUP BY meter
)
SELECT 
  ec.dataset,
  ec.exported_rows,
  rc.rollup_rows,
  ABS(ec.exported_rows - rc.rollup_rows) as row_diff,
  CASE 
    WHEN ABS(ec.exported_rows - rc.rollup_rows) <= 0.01 * rc.rollup_rows THEN 'PASS'
    ELSE 'FAIL'
  END as validation_status
FROM export_counts ec
LEFT JOIN rollup_counts rc ON ec.dataset = rc.dataset;
```

**Acceptable Variance:**
- ±1% for large datasets (>10K rows)
- ±10 rows for small datasets (<1K rows)
- Zero tolerance for invoices/billing data

### Phase 3: Schema Compliance (Required)

**Process:**
1. Validate exported data against contracts (Ch.16)
2. Check required fields are present
3. Verify data types and constraints
4. Ensure stable field names used

**Contract Validation:**
```python
# Pseudocode for schema validation
def validate_dataset_schema(dataset_name, exported_file, contract_file):
    contract = load_contract(contract_file)
    data_sample = load_sample_rows(exported_file, limit=1000)
    
    # Check required fields
    required_fields = contract['required_fields']
    missing_fields = set(required_fields) - set(data_sample.columns)
    if missing_fields:
        return f"MISSING_FIELDS: {missing_fields}"
    
    # Validate data types
    for field, expected_type in contract['field_types'].items():
        if field in data_sample.columns:
            actual_type = infer_type(data_sample[field])
            if not types_compatible(actual_type, expected_type):
                return f"TYPE_MISMATCH: {field} expected {expected_type}, got {actual_type}"
    
    # Check constraints
    for constraint in contract['constraints']:
        if not validate_constraint(data_sample, constraint):
            return f"CONSTRAINT_VIOLATION: {constraint}"
    
    return "PASS"
```

**Common Issues:**
- Missing fields due to schema evolution
- Type mismatches from export formatting
- Constraint violations in edge cases
- Deprecated field names in export views

### Phase 4: PII Audit (Conditional)

**When Required:**
- PII masking was applied
- Customer requested audit
- First export for new tenant
- Random compliance sampling

**Audit Process:**
1. Sample 1% of records with PII fields
2. Verify masking applied correctly
3. Check for data leakage in metadata
4. Validate irreversibility of masking

**Sample Checks:**
```sql
-- Check for unmasked email patterns
SELECT COUNT(*)
FROM export_sample
WHERE content ~ '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
  AND pii_masking_applied = true;
-- Should return 0

-- Check for credit card patterns  
SELECT COUNT(*)
FROM export_sample  
WHERE content ~ '\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'
  AND pii_masking_applied = true;
-- Should return 0

-- Verify hash consistency
SELECT content_hash, COUNT(DISTINCT original_content)
FROM export_audit_log
WHERE export_id = '{{export_id}}'
  AND masking_method = 'hash'
GROUP BY content_hash
HAVING COUNT(DISTINCT original_content) > 1;
-- Should return 0 (same input = same hash)
```

### Phase 5: Completeness Check (Required)

**Verification Steps:**
1. All requested datasets included
2. Date range coverage complete
3. No data gaps or missing partitions
4. File count matches manifest

**Completeness Queries:**
```sql
-- Check for data gaps by day
WITH date_series AS (
  SELECT generate_series(
    '{{export_start_date}}'::date,
    '{{export_end_date}}'::date,
    '1 day'::interval
  )::date as check_date
),
daily_counts AS (
  SELECT 
    date_trunc('day', created_at)::date as data_date,
    COUNT(*) as record_count
  FROM export_messages  -- repeat for each dataset
  GROUP BY 1
)
SELECT 
  ds.check_date,
  COALESCE(dc.record_count, 0) as records_found,
  CASE 
    WHEN dc.record_count IS NULL THEN 'MISSING_DATA'
    WHEN dc.record_count = 0 THEN 'NO_ACTIVITY'
    ELSE 'OK'
  END as status
FROM date_series ds
LEFT JOIN daily_counts dc ON ds.check_date = dc.data_date
WHERE ds.check_date NOT IN (
  -- Exclude known system outage dates
  SELECT outage_date FROM known_outages 
  WHERE tenant_id = '{{tenant_id}}'
)
ORDER BY ds.check_date;
```

## Remediation Procedures

### Hash Mismatch
1. **Root Cause**: File corruption during generation/transfer
2. **Action**: Regenerate affected file from source data
3. **Verification**: Re-run hash validation
4. **Prevention**: Add integrity checks during generation

### Row Count Variance
1. **Root Cause**: Investigate discrepancy source
2. **Minor Variance** (<1%): Document and proceed
3. **Major Variance** (>5%): Regenerate export
4. **Systematic Issues**: Fix export queries and reprocess

### Schema Violations
1. **Missing Fields**: Update export views to include
2. **Type Mismatches**: Fix type casting in queries
3. **Contract Changes**: Version contracts properly
4. **Field Renames**: Use stable export field names

### PII Leakage
1. **Immediate**: Stop export delivery
2. **Assessment**: Scope of data exposed
3. **Notification**: Alert security team
4. **Remediation**: Fix masking logic, regenerate
5. **Incident**: Follow security incident runbook

## Sign-off Process

### Automated Checks (Must Pass)
- [ ] All file hashes verified
- [ ] Row counts within acceptable variance
- [ ] Schema compliance validated
- [ ] No PII leakage detected

### Manual Review (If Required)
- [ ] Large export (>10GB) reviewed by senior engineer
- [ ] First-time tenant export spot-checked
- [ ] Legal hold data reviewed by compliance
- [ ] Custom masking rules validated

### Approval
- **Standard Exports**: Automated approval if all checks pass
- **Complex Exports**: Manual approval by export team lead
- **Sensitive Data**: Additional approval by compliance officer

## Documentation

### Verification Report
```json
{
  "export_id": "{{export_id}}",
  "verification_completed_at": "{{timestamp}}",
  "verified_by": "{{verifier_id}}",
  "checks_performed": {
    "hash_verification": "PASS",
    "row_count_validation": "PASS", 
    "schema_compliance": "PASS",
    "pii_audit": "PASS",
    "completeness_check": "PASS"
  },
  "issues_found": [],
  "remediation_actions": [],
  "approval_status": "APPROVED",
  "signed_off_by": "{{approver_id}}"
}
```

### DECISIONS.log Entry
```
<TIMESTAMP> | OPERATOR=<verifier> | ACTION=export_verified | EXPORT=<export_id> | CHECKS=hash+rows+schema+pii+complete | STATUS=<pass/fail> | ISSUES=<count> | EXECUTOR=<system>
```

## SLA Commitments

- **Hash Verification**: 100% of exports
- **Row Count Validation**: 100% of exports  
- **Schema Compliance**: 100% of exports
- **PII Audit**: 25% random sampling + all sensitive
- **Verification Time**: <2h for standard, <4h for complex

## Metrics & Monitoring

- Verification pass rate by check type
- Time to complete verification by export size
- Common failure modes and trends
- Customer satisfaction with data quality
