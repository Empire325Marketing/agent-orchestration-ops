# Export API Documentation

## Overview
The Export API allows authorized users to request and download tenant data exports. All operations require authentication and appropriate RBAC permissions (Ch.23).

## Authentication
- **Method**: JWT Bearer token
- **Required Role**: `admin` or `owner` (from Ch.23 permission matrix)
- **Scope**: Must have `tenant:export` permission for target tenant

## Request Export

### POST /v1/exports

Creates a new export request for the authenticated tenant.

**Request Schema:**
```json
{
  "datasets": ["messages", "tool_calls", "support_tickets", "invoices"],
  "format": "jsonl",  // "jsonl" | "parquet" | "csv"
  "date_range": {
    "start": "2024-01-01T00:00:00Z",
    "end": "2024-12-31T23:59:59Z"
  },
  "pii_masking": "redact",  // "none" | "redact" | "hash" | "truncate"
  "encryption": {
    "method": "pgp",  // "pgp" | "aes256"
    "public_key": "-----BEGIN PGP PUBLIC KEY BLOCK-----\n...",
    "passphrase_delivery": "email"  // for AES256 only
  },
  "delivery": {
    "method": "signed_url",  // "signed_url" | "customer_bucket"
    "bucket_uri": "s3://customer-bucket/exports/",  // if customer_bucket
    "notification": {
      "email": true,
      "webhook_url": "https://customer.com/webhooks/export"
    }
  },
  "options": {
    "include_embeddings": false,  // opt-in for large datasets
    "include_legal_hold": false,  // requires special permission
    "compression": "zstd"
  }
}
```

**Response:**
```json
{
  "export_id": "exp_2024_01_15_tenant123_abc123",
  "status": "requested",
  "estimated_completion": "2024-01-17T10:30:00Z",
  "estimated_size_bytes": 1073741824,
  "estimated_files": 15,
  "created_at": "2024-01-15T14:20:00Z"
}
```

**Status Codes:**
- `202 Accepted`: Export request queued successfully
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Authentication required
- `403 Forbidden`: Insufficient permissions
- `409 Conflict`: Active export already exists
- `429 Too Many Requests`: Rate limit exceeded

## Export Lifecycle States

### State Transitions
```
requested → validating → preparing → ready → downloaded → expired
                    ↓
                  failed
```

### State Descriptions
- **requested**: Export queued, awaiting validation
- **validating**: Checking permissions, data availability, legal holds
- **preparing**: Generating export files and manifest
- **ready**: Export available for download
- **downloaded**: Customer has accessed download URL
- **expired**: Download window closed (14 days)
- **failed**: Export generation failed, see error details

## Check Export Status

### GET /v1/exports/{export_id}

**Response:**
```json
{
  "export_id": "exp_2024_01_15_tenant123_abc123",
  "status": "ready",
  "progress": {
    "current_dataset": "tool_calls",
    "datasets_completed": 3,
    "datasets_total": 5,
    "progress_percentage": 60.0
  },
  "manifest": {
    "files": [
      {
        "path": "messages.jsonl.zst",
        "rows": 25000,
        "bytes": 1048576,
        "sha256": "a1b2c3d4..."
      }
    ],
    "total_rows": 125000,
    "total_bytes": 5242880,
    "schema_version": "1.0"
  },
  "download": {
    "signed_url": "https://exports.primarch.com/signed/...",
    "expires_at": "2024-01-29T14:20:00Z"
  },
  "created_at": "2024-01-15T14:20:00Z",
  "completed_at": "2024-01-16T09:15:00Z"
}
```

## List Exports

### GET /v1/exports

Lists export history for the authenticated tenant.

**Query Parameters:**
- `status`: Filter by status (`ready`, `failed`, etc.)
- `limit`: Number of results (default: 10, max: 100)
- `offset`: Pagination offset

**Response:**
```json
{
  "exports": [
    {
      "export_id": "exp_2024_01_15_tenant123_abc123",
      "status": "ready",
      "created_at": "2024-01-15T14:20:00Z",
      "datasets": ["messages", "tool_calls"],
      "format": "jsonl",
      "size_bytes": 5242880
    }
  ],
  "total": 25,
  "has_more": true
}
```

## Download Export

### GET /v1/exports/{export_id}/download

Returns the signed URL for downloading the export package.

**Response:**
```json
{
  "download_url": "https://exports.primarch.com/signed/...",
  "expires_at": "2024-01-29T14:20:00Z",
  "manifest_url": "https://exports.primarch.com/signed/.../manifest.json"
}
```

## Retry Failed Export

### POST /v1/exports/{export_id}/retry

Retries a failed export with the same parameters.

**Response:**
```json
{
  "export_id": "exp_2024_01_15_tenant123_abc123",
  "status": "requested",
  "retry_count": 1,
  "estimated_completion": "2024-01-17T10:30:00Z"
}
```

## Rate Limits

| Tier | Concurrent Exports | Monthly Requests | Retry Limit |
|------|-------------------|------------------|-------------|
| Free | 1 | 1 | 1 |
| Pro | 2 | 12 | 3 |
| Enterprise | 5 | Unlimited | 10 |

## Size Limits

| Tier | Max Export Size | Max File Count | Max Retention |
|------|----------------|----------------|---------------|
| Free | 1 GB | 10 | 7 days |
| Pro | 50 GB | 100 | 14 days |
| Enterprise | 1 TB | 1000 | 30 days |

## Error Handling

**Common Error Response:**
```json
{
  "error": {
    "code": "EXPORT_TOO_LARGE",
    "message": "Export size exceeds tier limit",
    "details": {
      "estimated_size": 75161927680,
      "tier_limit": 53687091200,
      "suggestion": "Reduce date range or exclude embeddings"
    }
  }
}
```

**Error Codes:**
- `EXPORT_TOO_LARGE`: Export exceeds size limits
- `INVALID_DATE_RANGE`: Start date after end date
- `DATASET_NOT_FOUND`: Requested dataset doesn't exist
- `ENCRYPTION_KEY_INVALID`: PGP key format error
- `LEGAL_HOLD_ACTIVE`: Cannot export data under legal hold
- `QUOTA_EXCEEDED`: Monthly export limit reached

## Webhooks

When an export status changes, a webhook notification is sent (if configured):

```json
{
  "event": "export.completed",
  "export_id": "exp_2024_01_15_tenant123_abc123",
  "tenant_id": "tenant123",
  "status": "ready",
  "download_url": "https://exports.primarch.com/signed/...",
  "timestamp": "2024-01-16T09:15:00Z"
}
```

**Webhook Events:**
- `export.completed`: Export ready for download
- `export.failed`: Export generation failed
- `export.expired`: Download window closed

## Security Considerations

- All exports are encrypted at rest and in transit
- Signed URLs are single-use and time-limited
- PII masking is irreversible - choose carefully
- Downloads are logged for audit purposes
- Legal hold data requires special authorization
