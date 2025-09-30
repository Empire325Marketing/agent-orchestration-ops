-- Audit Queries (documentation; not executed)

-- 1) Chain break detector (conceptual)
-- SELECT partition_key, COUNT(*) AS breaks FROM verify_hash_chain() GROUP BY 1 HAVING COUNT(*) > 0;

-- 2) Trace linkage ratio (last hour)
-- SELECT COALESCE(SUM(has_trace)::float/COUNT(*),0) AS coverage_ratio
-- FROM audit_logs WHERE ts > now() - interval '1 hour';

-- 3) Admin change spike (15m)
-- SELECT date_trunc('minute', ts) AS m, COUNT(*) FROM audit_logs
-- WHERE family='admin_change' AND ts > now() - interval '15 minutes'
-- GROUP BY 1 ORDER BY 1;

-- 4) Cross-tenant deny review
-- SELECT * FROM audit_logs WHERE family='security_event' AND action='cross_tenant_deny' AND ts > now() - interval '24 hours';
