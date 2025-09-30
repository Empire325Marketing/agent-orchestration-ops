# Export Request Processing

## Objective
Process tenant data export requests securely and efficiently while maintaining compliance and audit requirements.

## Trigger Events
- API request via POST /v1/exports
- Manual admin request for offboarding
- Legal/compliance data request
- Customer support escalation

## Prerequisites Check (within 1h)

### 1. Authentication & Authorization
- [ ] Verify JWT token validity and claims
- [ ] Confirm requestor has `admin` or `owner` role (Ch.23)
- [ ] Check `tenant:export` permission scope
- [ ] Validate tenant_id matches token claims

### 2. Legal & Compliance Review
- [ ] Check for active legal holds on tenant data
- [ ] Verify GDPR data subject rights (if applicable)
- [ ] Confirm retention policies allow export
- [ ] Review any export restrictions in tenant contract

### 3. Technical Feasibility
- [ ] Estimate export size against tier limits
- [ ] Check current export queue capacity
- [ ] Validate date range and dataset availability
- [ ] Verify encryption key format (if PGP)

## Request Processing (SLA: 72h Pro, 48h Enterprise)

### Phase 1: Preparation (0-6h)
1. **Queue Export Job**
   ```
   INSERT INTO export_jobs (
     export_id, tenant_id, status, requested_by,
     datasets, format, date_range, pii_masking,
     encryption_method, delivery_method, created_at
   ) VALUES (...);
   ```

2. **Create Working Directory**
   ```bash
   mkdir -p /exports/staging/${export_id}
   chmod 700 /exports/staging/${export_id}
   ```

3. **Encryption Key Setup**
   - PGP: Validate and import public key
   - AES256: Generate secure key, prepare handoff

### Phase 2: Data Extraction (6-48h)
1. **Execute Export Queries**
   - Run export views for each requested dataset
   - Apply PII masking per tenant preferences
   - Partition large datasets by date for streaming
   - Monitor progress and resource usage

2. **Format Conversion**
   - JSONL: Stream JSON objects with newline delimiters
   - Parquet: Use schema from data contracts (Ch.16)
   - CSV: Flatten nested structures, handle escaping

3. **File Generation**
   - Compress files per format specifications
   - Split large files at configured thresholds
   - Generate SHA256 hashes for integrity

### Phase 3: Encryption & Packaging (48-66h)
1. **Encrypt Files**
   ```bash
   # PGP encryption example
   gpg --trust-model always --encrypt \
       --recipient ${tenant_key_id} \
       --output ${file}.pgp ${file}
   
   # AES256 encryption example
   openssl enc -aes-256-cbc -pbkdf2 \
       -in ${file} -out ${file}.enc \
       -pass file:${keyfile}
   ```

2. **Generate Manifest**
   - Use manifest template with actual values
   - Include file inventory with hashes
   - Add validation checksums
   - Reference data contracts compliance

3. **Package for Delivery**
   - Create signed S3 URLs (14-day expiry)
   - Or upload to customer bucket if specified
   - Encrypt manifest separately

### Phase 4: Verification (66-72h)
1. **Data Integrity Checks**
   - Verify all file hashes match manifest
   - Compare row counts with usage rollups
   - Validate schema compliance per contracts
   - Run PII audit on sample data

2. **Delivery Preparation**
   - Test signed URL accessibility
   - Prepare download notifications
   - Update export status to "ready"

## Customer Notification

### Email Template
```
Subject: Data Export Ready - Export ID {{export_id}}

Your data export is ready for download.

Export Details:
- Export ID: {{export_id}}
- Created: {{created_at}}
- Datasets: {{datasets}}
- Format: {{format}}
- Size: {{total_size_mb}} MB
- Files: {{file_count}}

Download: {{download_url}}
Expires: {{expires_at}}

The download link is valid for 14 days. Please verify the SHA256 
checksums in the included manifest.json file.

Need help? Contact support with your Export ID.
```

### Webhook Notification
```json
{
  "event": "export.completed",
  "export_id": "{{export_id}}",
  "tenant_id": "{{tenant_id}}",
  "status": "ready",
  "download_url": "{{download_url}}",
  "expires_at": "{{expires_at}}",
  "manifest_hash": "{{manifest_sha256}}"
}
```

## Error Handling

### Common Failure Modes
1. **Data Too Large**: Split into multiple exports or exclude large datasets
2. **Encryption Key Invalid**: Request corrected key from customer
3. **Legal Hold Conflict**: Escalate to legal team for review
4. **Quota Exceeded**: Queue for next billing cycle or upgrade

### Recovery Actions
1. **Partial Failure**: Resume from last successful dataset
2. **Corruption Detected**: Regenerate affected files
3. **Timeout**: Extend deadline and continue processing
4. **Storage Full**: Cleanup old exports, add capacity

## Key Collection Process

### For PGP Encryption
1. Customer provides public key via secure channel
2. Validate key format and expiration
3. Import to temporary keyring
4. Test encryption with small sample
5. Store key fingerprint in export metadata

### For AES256 Encryption
1. Generate cryptographically secure 256-bit key
2. Create secure passphrase (12+ words)
3. Encrypt key with passphrase
4. Deliver passphrase via agreed out-of-band method
5. Destroy plaintext key after use

## Audit & Compliance

### Required Logging
- Export request details and authorization
- Data access patterns and row counts
- Encryption method and key fingerprints
- Download events and IP addresses
- Any errors or security events

### DECISIONS.log Entry
```
<TIMESTAMP> | OPERATOR=<requester> | ACTION=export_request | TENANT=<tenant_id> | DATASETS=<count> | SIZE=<bytes> | FORMAT=<format> | ENCRYPTION=<method> | STATUS=<status> | EXECUTOR=<system>
```

### Retention
- Export metadata: 7 years (compliance)
- Export files: Deleted after download window
- Access logs: 13 months (security audit)
- Encryption keys: Destroyed after delivery

## SLA Monitoring

### Key Metrics
- Time to completion by tier
- Success rate and failure reasons
- Customer satisfaction scores
- Data integrity verification results

### Escalation Triggers
- Export stalled >24h beyond SLA
- Multiple verification failures
- Customer complaint about data quality
- Security incident during processing

## Post-Delivery

### Customer Acknowledgment
- Confirm successful download
- Verify data integrity with customer
- Collect feedback on export quality
- Close export ticket in support system

### Cleanup
- Delete staging files after confirmation
- Remove temporary encryption keys
- Archive export metadata
- Update usage analytics
