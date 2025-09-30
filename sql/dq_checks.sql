-- Data Quality checks (read-only; run in CI or cron)
-- 1) messages: content present
SELECT 'messages_nonempty' AS check, COUNT(*) AS violations
FROM messages WHERE content IS NULL OR length(content)=0;

-- 2) tool_calls: non-negative latency
SELECT 'tool_calls_latency_nonneg' AS check, COUNT(*) AS violations
FROM tool_calls WHERE latency_ms < 0;

-- 3) embeddings: dimensional integrity
SELECT 'embeddings_dim' AS check, COUNT(*) AS violations
FROM embeddings WHERE dim <> 1536;
