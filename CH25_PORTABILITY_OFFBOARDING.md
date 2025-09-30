# Chapter 25 — Data Portability & Tenant Offboarding

## Decision Summary
We provide comprehensive data portability with multiple export formats (JSONL, Parquet, CSV) and secure delivery mechanisms. Tenant offboarding follows a controlled process: export → verify → disable → billing close-out → scheduled deletion per retention policies.

## Scope (MVP)
- **Export Formats**: JSONL (primary), Parquet (analytics), CSV (edge cases)
- **Data Coverage**: messages, tool_calls, embeddings, attachments metadata, support tickets, invoices
- **Encryption**: PGP (tenant-supplied public key) or AES-256 with secure passphrase handoff
- **Delivery**: Signed S3 URLs (14-day availability) or tenant-owned S3-compatible bucket
- **Verification**: SHA256 checksums, row count validation, schema compliance checks
- **SLAs**: Export completion within 72h (Pro), 48h (Enterprise); 14-day delivery window

## Non-Goals
- Real-time streaming exports (batch-only for MVP)
- Cross-cloud provider migrations (S3-compatible only)
- Granular date range filtering (full tenant export only)
- Legacy format support beyond CSV compatibility

## Export Formats

### JSONL (Primary)
- **Use Case**: API consumption, re-ingestion, general purpose
- **Compression**: zstd (default), gzip (compatibility)
- **Encoding**: UTF-8, LF line endings
- **Structure**: One JSON object per line with stable field names

### Parquet (Analytics)
- **Use Case**: Data warehouse import, columnar analytics
- **Compression**: Snappy (balance of speed/size)
- **Schema**: Strongly typed with metadata preservation
- **Partitioning**: By date for large datasets

### CSV (Edge Cases)
- **Use Case**: Legacy systems, simple tooling
- **Encoding**: UTF-8 with BOM, CRLF line endings
- **Escaping**: RFC 4180 compliant
- **Limitations**: Nested data flattened or JSON-encoded

## Data Coverage
- **messages**: All user-assistant conversations with PII masking options
- **tool_calls**: API invocations with request/response payloads
- **embeddings**: Vector data with associated metadata (opt-in due to size)
- **attachments_meta**: File metadata without binary content
- **support_tickets**: All customer service interactions
- **invoices**: Billing history and payment records

## Security & Encryption

### PGP Encryption (Recommended)
- Tenant provides RSA-4096 or Ed25519 public key
- Each export file encrypted separately for streaming
- Tenant retains private key for decryption

### AES-256 Alternative
- System-generated encryption key
- Secure passphrase delivery via out-of-band channel
- Single-use keys per export request

## Manifest & Integrity
Each export includes `manifest.json` with:
- Export metadata (ID, tenant, timestamp, schema version)
- File inventory (paths, row counts, byte sizes, SHA256 hashes)
- Data contracts compliance status (Ch.16 integration)
- Total counts cross-referenced with usage rollups

## Delivery Methods
- **Signed URLs**: Pre-signed S3 URLs valid for 14 days
- **Customer Bucket**: Direct delivery to tenant-owned S3-compatible storage
- **Notification**: Email + webhook notification when ready
- **Access Control**: Download URLs require authentication

## Verification Process
1. **Hash Verification**: SHA256 check for each file
2. **Row Count Validation**: Compare against usage_rollups_daily
3. **Schema Compliance**: Validate against data contracts (Ch.16)
4. **Completeness Check**: Ensure all requested datasets included
5. **PII Audit**: Verify masking applied per tenant settings

## Offboarding Workflow
1. **Export Phase**: Complete data export with verification
2. **Confirmation**: Tenant acknowledges successful download
3. **Access Disable**: Revoke API keys and disable authentication
4. **Billing Close-out**: Final invoice, payment collection (Ch.24)
5. **Retention Schedule**: Queue deletion per legal retention requirements (Ch.9)
6. **Deletion**: Secure wipe after retention period expires
7. **Audit Trail**: Complete DECISIONS.log documentation

## Ties to Other Chapters
- **Ch.6 Proxy**: Egress metering for export delivery
- **Ch.8 Secrets/IAM**: Vault-managed encryption keys and access control
- **Ch.9 Compliance**: Legal hold checks, GDPR deletion rights, retention policies
- **Ch.12 Cost**: Export generation costs and egress charges
- **Ch.16 Data Lineage**: Contract validation and schema compliance
- **Ch.23 RBAC**: Role-based authorization for export requests
- **Ch.24 Billing**: Account close-out and final reconciliation

## SLAs by Tier
- **Enterprise**: 48h export completion, dedicated support, unlimited retries
- **Pro**: 72h export completion, email support, 3 retries per month
- **Free**: Best effort (7 days), self-service only, 1 export per lifetime

## Retention During Export
- **Export Window**: 14 days for signed URL access
- **Retry Window**: 30 days for re-export requests
- **Verification Period**: 7 days for dispute resolution
- **Audit Retention**: Export logs retained per compliance requirements
