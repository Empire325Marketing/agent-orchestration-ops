-- /srv/primarch/sql/restore_validation.sql
-- Restore Validation Queries for DR Exercise

-- =============================================================================
-- DATABASE OVERVIEW & SIZE VERIFICATION
-- =============================================================================

\echo '=== DATABASE SIZE AND TABLE INFORMATION ==='
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats 
WHERE schemaname = 'public'
ORDER BY schemaname, tablename;

\dt+

-- =============================================================================
-- CRITICAL TABLE ROW COUNTS
-- =============================================================================

\echo '=== CRITICAL TABLE ROW COUNTS ==='
SELECT 'agents' as table_name, count(*) as row_count, 
       min(created_at) as earliest, max(updated_at) as latest
FROM agents
UNION ALL
SELECT 'tasks', count(*), min(created_at), max(updated_at) FROM tasks
UNION ALL  
SELECT 'executions', count(*), min(started_at), max(completed_at) FROM executions
UNION ALL
SELECT 'audit_log', count(*), min(created_at), max(created_at) FROM audit_log
UNION ALL
SELECT 'tool_calls', count(*), min(created_at), max(created_at) FROM tool_calls
UNION ALL
SELECT 'sessions', count(*), min(created_at), max(updated_at) FROM sessions
ORDER BY table_name;

-- =============================================================================
-- DATA INTEGRITY CHECKSUMS
-- =============================================================================

\echo '=== DATA INTEGRITY VERIFICATION ==='

-- Agents table checksum
SELECT 
    'agents' as table_name,
    count(*) as total_rows,
    md5(string_agg(
        COALESCE(agent_id::text, '') || 
        COALESCE(name, '') || 
        COALESCE(status, '') ||
        COALESCE(created_at::text, ''), 
        ''
    )) as content_hash
FROM (SELECT * FROM agents ORDER BY agent_id) t;

-- Tasks table checksum  
SELECT 
    'tasks' as table_name,
    count(*) as total_rows,
    md5(string_agg(
        COALESCE(task_id::text, '') ||
        COALESCE(agent_id::text, '') ||
        COALESCE(status, '') ||
        COALESCE(priority::text, '') ||
        COALESCE(created_at::text, ''),
        ''
    )) as content_hash
FROM (SELECT * FROM tasks ORDER BY task_id) t;

-- Executions table checksum
SELECT 
    'executions' as table_name,
    count(*) as total_rows,
    md5(string_agg(
        COALESCE(execution_id::text, '') ||
        COALESCE(task_id::text, '') ||
        COALESCE(status, '') ||
        COALESCE(started_at::text, ''),
        ''
    )) as content_hash
FROM (SELECT * FROM executions ORDER BY execution_id) t;

-- =============================================================================
-- AUDIT CHAIN VERIFICATION (NO BREAKS)
-- =============================================================================

\echo '=== AUDIT CHAIN VERIFICATION ==='

-- Full audit chain hash
SELECT 
    'audit_log' as table_name,
    count(*) as total_entries,
    min(created_at) as earliest_entry,
    max(created_at) as latest_entry,
    md5(string_agg(
        COALESCE(audit_id::text, '') ||
        COALESCE(entity_type, '') ||
        COALESCE(entity_id::text, '') ||
        COALESCE(action, '') ||
        COALESCE(audit_hash, '') ||
        COALESCE(created_at::text, ''),
        ''
    ORDER BY audit_id)) as chain_hash
FROM audit_log;

-- Verify no gaps in audit sequence
WITH audit_gaps AS (
    SELECT 
        audit_id,
        LAG(audit_id) OVER (ORDER BY audit_id) as prev_id,
        audit_id - LAG(audit_id) OVER (ORDER BY audit_id) as gap
    FROM audit_log
)
SELECT 
    count(*) as total_gaps,
    max(gap) as max_gap_size,
    count(*) FILTER (WHERE gap > 1) as suspicious_gaps
FROM audit_gaps;

-- =============================================================================
-- TEMPORAL CONSISTENCY CHECKS
-- =============================================================================

\echo '=== TEMPORAL CONSISTENCY VERIFICATION ==='

-- Check for future timestamps (data corruption indicator)
SELECT 
    'future_timestamps' as check_name,
    count(*) as violations
FROM (
    SELECT created_at FROM agents WHERE created_at > NOW()
    UNION ALL
    SELECT created_at FROM tasks WHERE created_at > NOW()  
    UNION ALL
    SELECT started_at FROM executions WHERE started_at > NOW()
    UNION ALL
    SELECT created_at FROM audit_log WHERE created_at > NOW()
) future_checks;

-- Check for NULL timestamps in critical fields
SELECT 
    'null_timestamps' as check_name,
    (
        (SELECT count(*) FROM agents WHERE created_at IS NULL) +
        (SELECT count(*) FROM tasks WHERE created_at IS NULL) +
        (SELECT count(*) FROM executions WHERE started_at IS NULL) +
        (SELECT count(*) FROM audit_log WHERE created_at IS NULL)
    ) as violations;

-- =============================================================================
-- REFERENTIAL INTEGRITY CHECKS
-- =============================================================================

\echo '=== REFERENTIAL INTEGRITY VERIFICATION ==='

-- Orphaned tasks (no valid agent)
SELECT 
    'orphaned_tasks' as check_name,
    count(*) as violations
FROM tasks t
LEFT JOIN agents a ON t.agent_id = a.agent_id
WHERE a.agent_id IS NULL;

-- Orphaned executions (no valid task)
SELECT 
    'orphaned_executions' as check_name,
    count(*) as violations  
FROM executions e
LEFT JOIN tasks t ON e.task_id = t.task_id
WHERE t.task_id IS NULL;

-- Orphaned tool calls (no valid execution)
SELECT 
    'orphaned_tool_calls' as check_name,
    count(*) as violations
FROM tool_calls tc
LEFT JOIN executions e ON tc.execution_id = e.execution_id  
WHERE e.execution_id IS NULL;

-- =============================================================================
-- RECOVERY WINDOW VALIDATION
-- =============================================================================

\echo '=== RECOVERY WINDOW DATA VERIFICATION ==='

-- Data within expected recovery window (last 15 minutes before backup)
SELECT 
    'recovery_window_agents' as table_name,
    count(*) as records_in_window
FROM agents 
WHERE created_at BETWEEN (NOW() - INTERVAL '30 minutes') AND (NOW() - INTERVAL '15 minutes');

SELECT 
    'recovery_window_tasks' as table_name,
    count(*) as records_in_window
FROM tasks
WHERE created_at BETWEEN (NOW() - INTERVAL '30 minutes') AND (NOW() - INTERVAL '15 minutes');

SELECT 
    'recovery_window_executions' as table_name,
    count(*) as records_in_window
FROM executions
WHERE started_at BETWEEN (NOW() - INTERVAL '30 minutes') AND (NOW() - INTERVAL '15 minutes');

-- =============================================================================
-- SUMMARY VALIDATION REPORT
-- =============================================================================

\echo '=== VALIDATION SUMMARY ==='

SELECT 
    'RESTORE_VALIDATION_COMPLETE' as status,
    NOW() as validation_timestamp,
    (
        SELECT count(*) FROM agents
    ) + (
        SELECT count(*) FROM tasks  
    ) + (
        SELECT count(*) FROM executions
    ) + (
        SELECT count(*) FROM audit_log
    ) as total_records_validated;

-- Generate final validation hash for comparison
SELECT 
    'FINAL_VALIDATION_HASH' as validation_type,
    md5(
        (SELECT md5(string_agg(agent_id::text || name, '')) FROM agents ORDER BY agent_id) ||
        (SELECT md5(string_agg(task_id::text || status, '')) FROM tasks ORDER BY task_id) ||
        (SELECT md5(string_agg(execution_id::text || status, '')) FROM executions ORDER BY execution_id) ||
        (SELECT md5(string_agg(audit_hash, '')) FROM audit_log ORDER BY audit_id)
    ) as composite_hash;

\echo 'Restore validation queries completed successfully.'
