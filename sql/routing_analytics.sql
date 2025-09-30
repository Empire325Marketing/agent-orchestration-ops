-- Routing Analytics Queries for Model Routing & Batching Optimization
-- Chapter 38 - Model Routing & Batching Optimization
-- Version: 1.0

-- ==============================================================================
-- PROVIDER DISTRIBUTION ANALYSIS
-- ==============================================================================

-- Provider share analysis for last 24 hours
-- Shows traffic distribution across all configured providers
SELECT 
    provider,
    model,
    route_tier,
    COUNT(*) as request_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as traffic_pct,
    AVG(latency_ms) as avg_latency_ms,
    ROUND(100.0 * SUM(CASE WHEN error_code IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate_pct
FROM router_events 
WHERE ts > NOW() - INTERVAL '24 hours'
GROUP BY provider, model, route_tier
ORDER BY request_count DESC;

-- Provider share over time (hourly breakdown for last 7 days)
SELECT 
    DATE_TRUNC('hour', ts) as hour_bucket,
    provider,
    COUNT(*) as request_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY DATE_TRUNC('hour', ts)), 2) as hourly_share_pct
FROM router_events 
WHERE ts > NOW() - INTERVAL '7 days'
GROUP BY hour_bucket, provider
ORDER BY hour_bucket DESC, request_count DESC;

-- Provider weight compliance analysis
-- Compares actual traffic distribution vs configured weights
WITH actual_distribution AS (
    SELECT 
        provider,
        model,
        COUNT(*) as actual_requests,
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY model) as actual_pct
    FROM router_events 
    WHERE ts > NOW() - INTERVAL '6 hours'
      AND error_code IS NULL  -- Only successful requests for weight analysis
    GROUP BY provider, model
),
configured_weights AS (
    SELECT 
        provider,
        model,
        configured_weight_pct
    FROM router_weight_config 
    WHERE is_active = true
)
SELECT 
    a.provider,
    a.model,
    a.actual_pct,
    COALESCE(c.configured_weight_pct, 0) as configured_pct,
    ABS(a.actual_pct - COALESCE(c.configured_weight_pct, 0)) as deviation_pct,
    CASE 
        WHEN ABS(a.actual_pct - COALESCE(c.configured_weight_pct, 0)) > 10 
        THEN 'OUT_OF_COMPLIANCE'
        WHEN ABS(a.actual_pct - COALESCE(c.configured_weight_pct, 0)) > 5 
        THEN 'MONITORING_REQUIRED'
        ELSE 'COMPLIANT'
    END as compliance_status
FROM actual_distribution a
LEFT JOIN configured_weights c ON a.provider = c.provider AND a.model = c.model
ORDER BY deviation_pct DESC;

-- ==============================================================================
-- COST ANALYSIS AND OPTIMIZATION
-- ==============================================================================

-- Cost per 1k tokens by provider and model (last 24 hours)
SELECT 
    provider,
    model,
    route_tier,
    tenant_id,
    COUNT(*) as request_count,
    SUM(tokens_input) as total_input_tokens,
    SUM(tokens_output) as total_output_tokens,
    SUM(tokens_input + tokens_output) as total_tokens,
    SUM(cost_usd) as total_cost_usd,
    ROUND(1000.0 * SUM(cost_usd) / NULLIF(SUM(tokens_output), 0), 6) as cost_per_1k_output_tokens,
    ROUND(1000.0 * SUM(cost_usd) / NULLIF(SUM(tokens_input + tokens_output), 0), 6) as cost_per_1k_total_tokens
FROM usage_events 
WHERE meter = 'tokens_out' 
  AND ts > NOW() - INTERVAL '24 hours'
GROUP BY provider, model, route_tier, tenant_id
ORDER BY total_cost_usd DESC;

-- Daily cost comparison vs baseline (7-day rolling average)
WITH daily_costs AS (
    SELECT 
        DATE_TRUNC('day', ts) as day_bucket,
        provider,
        SUM(cost_usd) as daily_cost
    FROM usage_events 
    WHERE ts > NOW() - INTERVAL '14 days'
    GROUP BY day_bucket, provider
),
baseline_costs AS (
    SELECT 
        provider,
        AVG(daily_cost) as baseline_avg_cost,
        STDDEV(daily_cost) as baseline_stddev
    FROM daily_costs 
    WHERE day_bucket <= DATE_TRUNC('day', NOW()) - INTERVAL '7 days'
    GROUP BY provider
)
SELECT 
    d.day_bucket,
    d.provider,
    d.daily_cost,
    b.baseline_avg_cost,
    ROUND(100.0 * (d.daily_cost - b.baseline_avg_cost) / b.baseline_avg_cost, 2) as variance_pct,
    CASE 
        WHEN d.daily_cost > b.baseline_avg_cost + 2 * b.baseline_stddev THEN 'ANOMALY_HIGH'
        WHEN d.daily_cost < b.baseline_avg_cost - 2 * b.baseline_stddev THEN 'ANOMALY_LOW'
        WHEN ABS(d.daily_cost - b.baseline_avg_cost) > 0.25 * b.baseline_avg_cost THEN 'ELEVATED_VARIANCE'
        ELSE 'NORMAL'
    END as cost_status
FROM daily_costs d
JOIN baseline_costs b ON d.provider = b.provider
WHERE d.day_bucket >= DATE_TRUNC('day', NOW()) - INTERVAL '7 days'
ORDER BY d.day_bucket DESC, variance_pct DESC;

-- Cost savings analysis (local vs cloud providers)
WITH provider_costs AS (
    SELECT 
        CASE 
            WHEN provider LIKE '%vllm%' OR provider LIKE '%local%' THEN 'local'
            ELSE 'cloud'
        END as provider_type,
        model,
        COUNT(*) as request_count,
        SUM(cost_usd) as total_cost,
        SUM(tokens_output) as total_tokens
    FROM usage_events 
    WHERE ts > NOW() - INTERVAL '24 hours'
    GROUP BY provider_type, model
),
cloud_baseline AS (
    SELECT 
        model,
        total_cost / NULLIF(total_tokens, 0) * 1000 as cloud_cost_per_1k
    FROM provider_costs 
    WHERE provider_type = 'cloud'
)
SELECT 
    pc.model,
    pc.provider_type,
    pc.request_count,
    pc.total_cost,
    ROUND(1000.0 * pc.total_cost / NULLIF(pc.total_tokens, 0), 6) as cost_per_1k_tokens,
    cb.cloud_cost_per_1k as cloud_baseline_cost_per_1k,
    CASE 
        WHEN pc.provider_type = 'local' AND cb.cloud_cost_per_1k > 0 
        THEN ROUND(100.0 * (cb.cloud_cost_per_1k - (1000.0 * pc.total_cost / NULLIF(pc.total_tokens, 0))) / cb.cloud_cost_per_1k, 2)
        ELSE NULL
    END as savings_pct,
    CASE 
        WHEN pc.provider_type = 'local' AND cb.cloud_cost_per_1k > 0 
        THEN ROUND((cb.cloud_cost_per_1k * pc.total_tokens / 1000.0) - pc.total_cost, 2)
        ELSE NULL
    END as savings_usd_24h
FROM provider_costs pc
LEFT JOIN cloud_baseline cb ON pc.model = cb.model
ORDER BY savings_usd_24h DESC NULLS LAST;

-- ==============================================================================
-- FALLBACK AND RELIABILITY ANALYSIS
-- ==============================================================================

-- Fallback usage patterns and success rates
SELECT 
    primary_provider,
    fallback_provider,
    model,
    COUNT(*) as fallback_attempts,
    SUM(CASE WHEN final_status = 'success' THEN 1 ELSE 0 END) as successful_fallbacks,
    ROUND(100.0 * SUM(CASE WHEN final_status = 'success' THEN 1 ELSE 0 END) / COUNT(*), 2) as fallback_success_rate,
    AVG(total_latency_ms) as avg_total_latency_ms,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as fallback_share_pct
FROM router_events 
WHERE is_fallback = true
  AND ts > NOW() - INTERVAL '24 hours'
GROUP BY primary_provider, fallback_provider, model
ORDER BY fallback_attempts DESC;

-- Provider reliability over time (error rates by hour)
SELECT 
    DATE_TRUNC('hour', ts) as hour_bucket,
    provider,
    model,
    COUNT(*) as total_requests,
    SUM(CASE WHEN error_code IS NOT NULL THEN 1 ELSE 0 END) as error_count,
    ROUND(100.0 * SUM(CASE WHEN error_code IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate_pct,
    ROUND(AVG(latency_ms), 2) as avg_latency_ms
FROM router_events 
WHERE ts > NOW() - INTERVAL '48 hours'
GROUP BY hour_bucket, provider, model
HAVING COUNT(*) >= 10  -- Only include hours with meaningful volume
ORDER BY hour_bucket DESC, error_rate_pct DESC;

-- Circuit breaker activation analysis
SELECT 
    provider,
    model,
    DATE_TRUNC('day', triggered_at) as day_bucket,
    COUNT(*) as activations,
    AVG(EXTRACT(EPOCH FROM reset_at - triggered_at)) as avg_open_duration_seconds,
    SUM(requests_blocked) as total_blocked_requests,
    array_agg(DISTINCT trigger_reason) as trigger_reasons
FROM circuit_breaker_events 
WHERE triggered_at > NOW() - INTERVAL '7 days'
GROUP BY provider, model, day_bucket
ORDER BY day_bucket DESC, activations DESC;

-- ==============================================================================
-- PERFORMANCE AND LATENCY ANALYSIS  
-- ==============================================================================

-- Latency percentiles by provider and model (last 6 hours)
SELECT 
    provider,
    model,
    route_tier,
    COUNT(*) as request_count,
    ROUND(AVG(latency_ms), 2) as avg_latency_ms,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY latency_ms), 2) as p50_latency_ms,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms), 2) as p95_latency_ms,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY latency_ms), 2) as p99_latency_ms,
    MAX(latency_ms) as max_latency_ms
FROM router_events 
WHERE ts > NOW() - INTERVAL '6 hours'
  AND error_code IS NULL
  AND latency_ms IS NOT NULL
GROUP BY provider, model, route_tier
HAVING COUNT(*) >= 50  -- Require meaningful sample size
ORDER BY p95_latency_ms DESC;

-- Latency trends over time (daily averages for last 30 days)
SELECT 
    DATE_TRUNC('day', ts) as day_bucket,
    provider,
    model,
    COUNT(*) as daily_requests,
    ROUND(AVG(latency_ms), 2) as avg_latency_ms,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY latency_ms), 2) as p95_latency_ms,
    ROUND(STDDEV(latency_ms), 2) as latency_stddev
FROM router_events 
WHERE ts > NOW() - INTERVAL '30 days'
  AND error_code IS NULL
  AND latency_ms IS NOT NULL
GROUP BY day_bucket, provider, model
HAVING COUNT(*) >= 100  -- Require meaningful daily volume
ORDER BY day_bucket DESC, p95_latency_ms DESC;

-- Queue depth and batching efficiency (vLLM specific)
SELECT 
    gpu_pool,
    DATE_TRUNC('hour', ts) as hour_bucket,
    AVG(queue_depth) as avg_queue_depth,
    MAX(queue_depth) as max_queue_depth,
    AVG(batch_utilization_pct) as avg_batch_utilization,
    AVG(kv_cache_hit_rate) as avg_cache_hit_rate,
    AVG(tokens_per_second) as avg_throughput_tps
FROM vllm_metrics 
WHERE ts > NOW() - INTERVAL '24 hours'
GROUP BY gpu_pool, hour_bucket
ORDER BY hour_bucket DESC, gpu_pool;

-- ==============================================================================
-- BATCH PROCESSING ANALYSIS
-- ==============================================================================

-- Batch processing performance by profile
SELECT 
    profile,
    DATE_TRUNC('day', created_at) as day_bucket,
    COUNT(*) as total_batches,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_batches,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed_batches,
    ROUND(100.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate_pct,
    ROUND(AVG(EXTRACT(EPOCH FROM completed_at - created_at) / 3600.0), 2) as avg_processing_hours,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM completed_at - created_at) / 3600.0), 2) as p95_processing_hours,
    AVG(item_count) as avg_items_per_batch,
    SUM(total_cost_usd) as total_cost
FROM batch_jobs 
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY profile, day_bucket
ORDER BY day_bucket DESC, total_cost DESC;

-- SLA compliance analysis for batch processing
SELECT 
    profile,
    sla_hours,
    COUNT(*) as total_batches,
    SUM(CASE 
        WHEN completed_at IS NOT NULL AND EXTRACT(EPOCH FROM completed_at - created_at) / 3600.0 <= sla_hours 
        THEN 1 ELSE 0 
    END) as within_sla,
    SUM(CASE 
        WHEN completed_at IS NULL AND EXTRACT(EPOCH FROM NOW() - created_at) / 3600.0 > sla_hours 
        THEN 1 
        WHEN completed_at IS NOT NULL AND EXTRACT(EPOCH FROM completed_at - created_at) / 3600.0 > sla_hours 
        THEN 1 
        ELSE 0 
    END) as sla_breaches,
    ROUND(100.0 * SUM(CASE 
        WHEN completed_at IS NOT NULL AND EXTRACT(EPOCH FROM completed_at - created_at) / 3600.0 <= sla_hours 
        THEN 1 ELSE 0 
    END) / COUNT(*), 2) as sla_compliance_pct
FROM batch_jobs 
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY profile, sla_hours
ORDER BY sla_compliance_pct ASC;

-- Batch cost efficiency analysis
SELECT 
    profile,
    COUNT(*) as batch_count,
    SUM(item_count) as total_items,
    SUM(total_cost_usd) as total_cost,
    ROUND(AVG(total_cost_usd / NULLIF(item_count, 0)), 6) as avg_cost_per_item,
    ROUND(1000.0 * SUM(total_cost_usd) / NULLIF(SUM(tokens_output), 0), 6) as cost_per_1k_tokens,
    -- Compare to equivalent sync API cost estimate
    ROUND(SUM(total_cost_usd), 2) as batch_cost,
    ROUND(SUM(estimated_sync_cost_usd), 2) as estimated_sync_cost,
    ROUND(100.0 * (SUM(estimated_sync_cost_usd) - SUM(total_cost_usd)) / NULLIF(SUM(estimated_sync_cost_usd), 0), 2) as savings_pct
FROM batch_jobs 
WHERE status = 'completed'
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY profile
ORDER BY savings_pct DESC;

-- ==============================================================================
-- TENANT AND USAGE ANALYTICS
-- ==============================================================================

-- Top tenants by usage and cost (last 24 hours)
SELECT 
    tenant_id,
    COUNT(DISTINCT model) as models_used,
    COUNT(DISTINCT provider) as providers_used,
    COUNT(*) as total_requests,
    SUM(tokens_input) as total_input_tokens,
    SUM(tokens_output) as total_output_tokens,
    SUM(cost_usd) as total_cost_usd,
    ROUND(AVG(latency_ms), 2) as avg_latency_ms,
    ROUND(100.0 * SUM(CASE WHEN error_code IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as error_rate_pct
FROM usage_events ue
JOIN router_events re ON ue.request_id = re.request_id
WHERE ue.ts > NOW() - INTERVAL '24 hours'
GROUP BY tenant_id
ORDER BY total_cost_usd DESC
LIMIT 20;

-- Route tier utilization analysis
SELECT 
    route_tier,
    COUNT(*) as request_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as usage_pct,
    SUM(cost_usd) as total_cost,
    ROUND(1000.0 * SUM(cost_usd) / NULLIF(SUM(tokens_output), 0), 6) as cost_per_1k_tokens,
    COUNT(DISTINCT tenant_id) as unique_tenants,
    AVG(latency_ms) as avg_latency_ms
FROM usage_events ue
JOIN router_events re ON ue.request_id = re.request_id
WHERE ue.ts > NOW() - INTERVAL '24 hours'
GROUP BY route_tier
ORDER BY usage_pct DESC;

-- ==============================================================================
-- OPERATIONAL HEALTH QUERIES
-- ==============================================================================

-- Current system status summary
SELECT 
    'Router Health' as metric_category,
    COUNT(*) as total_requests_1h,
    ROUND(100.0 * SUM(CASE WHEN error_code IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate_pct,
    ROUND(AVG(latency_ms), 2) as avg_latency_ms,
    ROUND(100.0 * SUM(CASE WHEN is_fallback THEN 1 ELSE 0 END) / COUNT(*), 2) as fallback_rate_pct
FROM router_events 
WHERE ts > NOW() - INTERVAL '1 hour'

UNION ALL

SELECT 
    'Cost Control' as metric_category,
    NULL as total_requests_1h,
    NULL as success_rate_pct,
    ROUND(SUM(cost_usd), 2) as avg_latency_ms,  -- Reusing column for hourly cost
    NULL as fallback_rate_pct
FROM usage_events 
WHERE ts > NOW() - INTERVAL '1 hour'

UNION ALL

SELECT 
    'vLLM Performance' as metric_category,
    NULL as total_requests_1h,
    ROUND(AVG(batch_utilization_pct), 2) as success_rate_pct,  -- Reusing for batch util
    ROUND(AVG(kv_cache_hit_rate), 2) as avg_latency_ms,      -- Reusing for cache hit
    NULL as fallback_rate_pct
FROM vllm_metrics 
WHERE ts > NOW() - INTERVAL '1 hour';

-- Active incidents and issues requiring attention
SELECT 
    issue_type,
    provider,
    model,
    issue_description,
    first_detected,
    NOW() - first_detected as duration,
    severity,
    impact_description
FROM (
    -- High error rate detection
    SELECT 
        'HIGH_ERROR_RATE' as issue_type,
        provider,
        model,
        'Error rate: ' || ROUND(100.0 * SUM(CASE WHEN error_code IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) || '%' as issue_description,
        MIN(ts) as first_detected,
        'P1' as severity,
        'Affecting ' || COUNT(*) || ' requests in last hour' as impact_description
    FROM router_events 
    WHERE ts > NOW() - INTERVAL '1 hour'
    GROUP BY provider, model
    HAVING 100.0 * SUM(CASE WHEN error_code IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) > 5
    
    UNION ALL
    
    -- Circuit breaker activations
    SELECT 
        'CIRCUIT_BREAKER_OPEN' as issue_type,
        provider,
        model,
        'Circuit breaker opened: ' || trigger_reason as issue_description,
        triggered_at as first_detected,
        'P1' as severity,
        'Blocking requests to ' || provider || '/' || model as impact_description
    FROM circuit_breaker_events 
    WHERE state = 'open' 
      AND triggered_at > NOW() - INTERVAL '1 hour'
      
    UNION ALL
    
    -- Stuck batch jobs
    SELECT 
        'STUCK_BATCH' as issue_type,
        'batch' as provider,
        profile as model,
        'Batch stuck in ' || status || ' for ' || EXTRACT(EPOCH FROM NOW() - updated_at)/3600 || ' hours' as issue_description,
        updated_at as first_detected,
        'P2' as severity,
        'Affecting ' || item_count || ' items' as impact_description
    FROM batch_jobs 
    WHERE status IN ('submitted', 'in_progress')
      AND updated_at < NOW() - INTERVAL '2 hours'
) issues
ORDER BY severity, first_detected;
