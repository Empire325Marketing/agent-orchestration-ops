-- Export Views (Documentation Only - DO NOT EXECUTE)
-- Read-only views for data export generation

-- Messages export view with PII masking options
-- CREATE VIEW export_messages AS
SELECT 
  m.id as message_id,
  m.session_id,
  m.created_at as timestamp,
  m.role,
  -- PII masking applied based on tenant export preferences
  CASE 
    WHEN @pii_masking = 'redact' THEN '[REDACTED]'
    WHEN @pii_masking = 'hash' THEN encode(sha256(m.content || @salt), 'hex')
    WHEN @pii_masking = 'truncate' THEN left(m.content, 50) || '...'
    ELSE m.content
  END as content,
  m.model,
  m.token_count,
  m.estimated_cost,
  -- Export metadata
  @export_id as export_id,
  @schema_version as schema_version
FROM messages m
WHERE m.tenant_id = @tenant_id
  AND m.created_at >= @export_start_date
  AND m.created_at <= @export_end_date
  AND (m.legal_hold = false OR @include_legal_hold = true)
ORDER BY m.created_at;

-- Tool calls export view
-- CREATE VIEW export_tool_calls AS
SELECT 
  tc.id as call_id,
  tc.message_id,
  tc.created_at as timestamp,
  tc.tool as tool_name,
  tc.endpoint,
  -- PII masking for request/response payloads
  CASE 
    WHEN @pii_masking = 'redact_keys' THEN 
      json_remove_keys(tc.request, @redact_keys_list)
    WHEN @pii_masking = 'hash_values' THEN
      json_hash_values(tc.request, @salt)
    ELSE tc.request
  END as request_payload,
  CASE 
    WHEN @pii_masking = 'redact_keys' THEN 
      json_remove_keys(tc.response, @redact_keys_list)
    WHEN @pii_masking = 'hash_values' THEN
      json_hash_values(tc.response, @salt)
    ELSE tc.response
  END as response_payload,
  tc.status as status_code,
  tc.latency_ms,
  tc.cost,
  @export_id as export_id,
  @schema_version as schema_version
FROM tool_calls tc
WHERE tc.tenant_id = @tenant_id
  AND tc.created_at >= @export_start_date
  AND tc.created_at <= @export_end_date
ORDER BY tc.created_at;

-- Embeddings export view (opt-in only)
-- CREATE VIEW export_embeddings AS
SELECT 
  e.id as embedding_id,
  CASE 
    WHEN @pii_masking = 'redact' THEN '[REDACTED]'
    WHEN @pii_masking = 'hash' THEN encode(sha256(e.text || @salt), 'hex')
    ELSE e.text
  END as text_content,
  e.embedding as vector_data,
  e.model,
  e.created_at as timestamp,
  e.metadata,
  @export_id as export_id,
  @schema_version as schema_version
FROM embeddings e
WHERE e.tenant_id = @tenant_id
  AND e.created_at >= @export_start_date
  AND e.created_at <= @export_end_date
  AND @include_embeddings = true  -- explicit opt-in required
ORDER BY e.created_at;

-- Attachments metadata export view (no binary content)
-- CREATE VIEW export_attachments_meta AS
SELECT 
  a.id as attachment_id,
  a.message_id,
  -- Filename may contain PII
  CASE 
    WHEN @pii_masking = 'redact' THEN '[REDACTED_FILENAME]'
    ELSE a.filename
  END as filename,
  a.content_type,
  a.size as size_bytes,
  a.created_at as upload_timestamp,
  a.hash as hash_sha256,
  @export_id as export_id,
  @schema_version as schema_version
FROM attachments a
WHERE a.tenant_id = @tenant_id
  AND a.created_at >= @export_start_date
  AND a.created_at <= @export_end_date
ORDER BY a.created_at;

-- Support tickets export view
-- CREATE VIEW export_support_tickets AS
SELECT 
  st.id as ticket_id,
  st.created_at as created_timestamp,
  st.channel,
  st.kind as category,
  st.severity,
  -- PII masking for title and description
  CASE 
    WHEN @pii_masking = 'redact' THEN '[REDACTED]'
    ELSE st.title
  END as title,
  CASE 
    WHEN @pii_masking = 'redact' THEN '[REDACTED]'
    ELSE st.description
  END as description,
  st.status,
  CASE 
    WHEN @pii_masking = 'redact' THEN '[REDACTED]'
    ELSE st.resolution
  END as resolution,
  @export_id as export_id,
  @schema_version as schema_version
FROM support_tickets st
WHERE st.customer_org_id = @org_id  -- org-level for support
  AND st.created_at >= @export_start_date
  AND st.created_at <= @export_end_date
ORDER BY st.created_at;

-- Invoices export view
-- CREATE VIEW export_invoices AS
SELECT 
  i.invoice_id,
  i.period_start,
  i.period_end,
  i.subtotal,
  i.credits,
  i.total,
  i.status,
  i.created_at as issued_date,
  i.due_at as due_date,
  -- Include line items as JSON array
  (
    SELECT json_agg(
      json_build_object(
        'meter', ii.meter,
        'quantity', ii.quantity,
        'rate', ii.rate,
        'amount', ii.amount,
        'description', ii.description
      )
    )
    FROM invoice_items ii 
    WHERE ii.invoice_id = i.invoice_id
  ) as line_items,
  @export_id as export_id,
  @schema_version as schema_version
FROM invoices i
WHERE i.tenant_id = @tenant_id
  AND i.period_start >= @export_start_date
  AND i.period_end <= @export_end_date
ORDER BY i.period_start;

-- Export job progress tracking
-- CREATE VIEW export_progress AS
SELECT 
  dataset_name,
  total_rows,
  exported_rows,
  ROUND((exported_rows::float / NULLIF(total_rows, 0)) * 100, 2) as progress_pct,
  estimated_completion,
  current_file,
  status
FROM export_job_status 
WHERE export_id = @export_id;

-- Partition hints for large datasets
-- For messages table partitioned by month:
-- SELECT * FROM messages_2024_01 WHERE tenant_id = @tenant_id
-- UNION ALL SELECT * FROM messages_2024_02 WHERE tenant_id = @tenant_id
-- ... (dynamic partition selection based on date range)

-- Row count validation query
-- SELECT 
--   'messages' as dataset,
--   COUNT(*) as export_count,
--   (SELECT SUM(quantity) FROM usage_rollups_daily 
--    WHERE tenant_id = @tenant_id 
--      AND meter = 'messages_stored'
--      AND date BETWEEN @export_start_date AND @export_end_date) as rollup_count
-- FROM export_messages;

-- PII audit query
-- SELECT 
--   dataset_name,
--   field_name,
--   pii_flag,
--   masking_applied,
--   sample_values[1:3] as sample  -- first 3 values for spot check
-- FROM export_pii_audit 
-- WHERE export_id = @export_id;
