-- Vulnerability Management Queries

-- Active vulnerabilities by severity
SELECT 
    severity,
    COUNT(*) as count,
    AVG(EXTRACT(epoch FROM (NOW() - first_seen))/3600) as avg_age_hours
FROM vulnerabilities 
WHERE status IN ('new', 'triaging', 'confirmed', 'mitigating')
GROUP BY severity
ORDER BY 
    CASE severity 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        WHEN 'low' THEN 4 
    END;

-- SLA compliance by severity
WITH sla_targets AS (
    SELECT 'critical' as severity, 48 as hours_sla
    UNION SELECT 'high', 168 -- 7 days
    UNION SELECT 'medium', 720 -- 30 days  
    UNION SELECT 'low', 2160 -- 90 days
)
SELECT 
    v.severity,
    COUNT(*) as total,
    COUNT(CASE WHEN EXTRACT(epoch FROM (NOW() - v.first_seen))/3600 > s.hours_sla THEN 1 END) as breached,
    ROUND(100.0 * COUNT(CASE WHEN EXTRACT(epoch FROM (NOW() - v.first_seen))/3600 <= s.hours_sla THEN 1 END) / COUNT(*), 2) as compliance_pct
FROM vulnerabilities v
JOIN sla_targets s ON v.severity = s.severity
WHERE v.status IN ('new', 'triaging', 'confirmed', 'mitigating')
GROUP BY v.severity, s.hours_sla;

-- Components with most vulnerabilities
SELECT 
    component,
    version,
    COUNT(*) as vuln_count,
    STRING_AGG(DISTINCT severity, ', ' ORDER BY severity) as severities,
    MAX(first_seen) as latest_vuln
FROM vulnerabilities
WHERE status IN ('new', 'triaging', 'confirmed', 'mitigating')
GROUP BY component, version
ORDER BY vuln_count DESC
LIMIT 20;

-- Exception tracking
SELECT 
    cve_id,
    component,
    severity,
    exception_reason,
    approved_by,
    expires_at,
    compensating_controls
FROM vulnerability_exceptions
WHERE expires_at > NOW()
ORDER BY expires_at;

-- Patch window effectiveness
SELECT 
    DATE_TRUNC('week', resolved_at) as week,
    COUNT(*) as vulnerabilities_resolved,
    AVG(EXTRACT(epoch FROM (resolved_at - first_seen))/3600) as avg_resolution_hours
FROM vulnerabilities
WHERE status = 'resolved' 
    AND resolved_at >= NOW() - INTERVAL '3 months'
GROUP BY DATE_TRUNC('week', resolved_at)
ORDER BY week;
