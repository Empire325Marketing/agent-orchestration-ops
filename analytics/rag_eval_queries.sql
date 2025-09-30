-- RAG 2.0 Evaluation Queries
-- Analytics queries for measuring retrieval quality, performance, and system health

-- ======================
-- RETRIEVAL QUALITY METRICS
-- ======================

-- Retrieval Recall at K
-- Measures what percentage of relevant documents were retrieved
WITH recall_metrics AS (
    SELECT 
        query_id,
        query_text,
        evaluation_date,
        ARRAY_LENGTH(relevant_doc_ids, 1) as total_relevant,
        ARRAY_LENGTH(
            ARRAY(
                SELECT unnest(retrieved_doc_ids) 
                INTERSECT 
                SELECT unnest(relevant_doc_ids)
            ), 1
        ) as relevant_retrieved
    FROM rag_evaluation_results
    WHERE evaluation_date >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT 
    evaluation_date,
    AVG(CASE WHEN total_relevant > 0 THEN relevant_retrieved::float / total_relevant ELSE 0 END) as avg_recall_at_10,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CASE WHEN total_relevant > 0 THEN relevant_retrieved::float / total_relevant ELSE 0 END) as median_recall_at_10,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY CASE WHEN total_relevant > 0 THEN relevant_retrieved::float / total_relevant ELSE 0 END) as p95_recall_at_10,
    COUNT(*) as num_queries
FROM recall_metrics
GROUP BY evaluation_date
ORDER BY evaluation_date DESC;

-- NDCG at K (Normalized Discounted Cumulative Gain)
-- Measures ranking quality considering position of relevant documents
SELECT 
    evaluation_date,
    AVG(ndcg_at_10) as avg_ndcg_at_10,
    AVG(ndcg_at_5) as avg_ndcg_at_5,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ndcg_at_10) as median_ndcg_at_10,
    STDDEV(ndcg_at_10) as stddev_ndcg_at_10,
    COUNT(*) as num_queries
FROM rag_evaluation_results
WHERE evaluation_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY evaluation_date
ORDER BY evaluation_date DESC;

-- Mean Reciprocal Rank (MRR)
-- Measures how quickly the first relevant document appears
SELECT 
    DATE_TRUNC('day', evaluation_date) as date,
    AVG(mrr) as mean_reciprocal_rank,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY mrr) as median_mrr,
    COUNT(CASE WHEN mrr > 0.8 THEN 1 END)::float / COUNT(*) as queries_with_high_mrr,
    COUNT(*) as total_queries
FROM rag_evaluation_results
WHERE evaluation_date >= CURRENT_DATE - INTERVAL '14 days'
  AND mrr IS NOT NULL
GROUP BY DATE_TRUNC('day', evaluation_date)
ORDER BY date DESC;

-- Retrieval vs Rerank Quality Improvement
-- Measures how much reranking improves retrieval quality
SELECT 
    DATE_TRUNC('week', r.evaluation_date) as week,
    AVG(r.ndcg_at_10) as avg_retrieval_ndcg,
    AVG(r.rerank_ndcg_at_10) as avg_rerank_ndcg,
    AVG(r.rerank_ndcg_at_10 - r.ndcg_at_10) as avg_rerank_improvement,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.rerank_ndcg_at_10 - r.ndcg_at_10) as median_rerank_improvement,
    COUNT(CASE WHEN r.rerank_ndcg_at_10 > r.ndcg_at_10 THEN 1 END)::float / COUNT(*) as improvement_rate,
    COUNT(*) as num_evaluations
FROM rag_evaluation_results r
WHERE r.evaluation_date >= CURRENT_DATE - INTERVAL '8 weeks'
  AND r.rerank_ndcg_at_10 IS NOT NULL
  AND r.ndcg_at_10 IS NOT NULL
GROUP BY DATE_TRUNC('week', r.evaluation_date)
ORDER BY week DESC;

-- ======================
-- PERFORMANCE METRICS
-- ======================

-- Retrieval Latency Analysis
-- P50, P95, P99 latency for different pipeline stages
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY retrieval_duration_ms) as p50_retrieval_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY retrieval_duration_ms) as p95_retrieval_ms,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY retrieval_duration_ms) as p99_retrieval_ms,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rerank_duration_ms) as p50_rerank_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY rerank_duration_ms) as p95_rerank_ms,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY rerank_duration_ms) as p99_rerank_ms,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_duration_ms) as p50_total_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_duration_ms) as p95_total_ms,
    COUNT(*) as num_requests
FROM rag_performance_logs
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour DESC;

-- Reranking Performance Analysis
-- Detailed analysis of reranking latency vs number of documents
SELECT 
    CASE 
        WHEN num_documents_reranked <= 10 THEN '1-10'
        WHEN num_documents_reranked <= 25 THEN '11-25'
        WHEN num_documents_reranked <= 50 THEN '26-50'
        WHEN num_documents_reranked <= 100 THEN '51-100'
        ELSE '100+'
    END as document_range,
    COUNT(*) as num_requests,
    AVG(rerank_duration_ms) as avg_rerank_duration_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY rerank_duration_ms) as p95_rerank_duration_ms,
    AVG(rerank_duration_ms::float / num_documents_reranked) as avg_ms_per_document,
    COUNT(CASE WHEN rerank_duration_ms > 200 THEN 1 END) as requests_over_200ms,
    COUNT(CASE WHEN rerank_duration_ms > 200 THEN 1 END)::float / COUNT(*) as slow_request_rate
FROM rag_performance_logs
WHERE timestamp >= NOW() - INTERVAL '7 days'
  AND num_documents_reranked > 0
  AND rerank_duration_ms IS NOT NULL
GROUP BY CASE 
    WHEN num_documents_reranked <= 10 THEN '1-10'
    WHEN num_documents_reranked <= 25 THEN '11-25'
    WHEN num_documents_reranked <= 50 THEN '26-50'
    WHEN num_documents_reranked <= 100 THEN '51-100'
    ELSE '100+'
END
ORDER BY MIN(num_documents_reranked);

-- Throughput Analysis
-- Requests per minute and concurrency metrics
SELECT 
    DATE_TRUNC('minute', timestamp) as minute,
    COUNT(*) as requests_per_minute,
    AVG(concurrent_requests) as avg_concurrent_requests,
    MAX(concurrent_requests) as peak_concurrent_requests,
    AVG(queue_wait_ms) as avg_queue_wait_ms,
    COUNT(CASE WHEN queue_wait_ms > 1000 THEN 1 END) as requests_with_long_wait
FROM rag_performance_logs
WHERE timestamp >= NOW() - INTERVAL '2 hours'
GROUP BY DATE_TRUNC('minute', timestamp)
ORDER BY minute DESC;

-- ======================
-- QUALITY DEGRADATION DETECTION
-- ======================

-- Quality Trend Analysis
-- Detect quality degradation over time
WITH quality_trends AS (
    SELECT 
        DATE_TRUNC('day', evaluation_date) as day,
        AVG(ndcg_at_10) as avg_ndcg,
        AVG(mrr) as avg_mrr,
        AVG(context_precision) as avg_context_precision,
        AVG(answer_relevancy) as avg_answer_relevancy,
        COUNT(*) as num_evaluations
    FROM rag_evaluation_results
    WHERE evaluation_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE_TRUNC('day', evaluation_date)
),
quality_with_lag AS (
    SELECT 
        *,
        LAG(avg_ndcg, 1) OVER (ORDER BY day) as prev_day_ndcg,
        LAG(avg_mrr, 1) OVER (ORDER BY day) as prev_day_mrr,
        LAG(avg_context_precision, 1) OVER (ORDER BY day) as prev_day_precision
    FROM quality_trends
)
SELECT 
    day,
    avg_ndcg,
    avg_mrr,
    avg_context_precision,
    avg_answer_relevancy,
    CASE 
        WHEN prev_day_ndcg IS NOT NULL THEN 
            (avg_ndcg - prev_day_ndcg) / prev_day_ndcg * 100
        ELSE NULL 
    END as ndcg_change_pct,
    CASE 
        WHEN prev_day_mrr IS NOT NULL THEN 
            (avg_mrr - prev_day_mrr) / prev_day_mrr * 100
        ELSE NULL 
    END as mrr_change_pct,
    num_evaluations
FROM quality_with_lag
WHERE day >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY day DESC;

-- Anomaly Detection
-- Identify queries with unusually poor performance
WITH performance_stats AS (
    SELECT 
        AVG(ndcg_at_10) as avg_ndcg,
        STDDEV(ndcg_at_10) as stddev_ndcg,
        AVG(total_duration_ms) as avg_duration,
        STDDEV(total_duration_ms) as stddev_duration
    FROM rag_evaluation_results r
    JOIN rag_performance_logs p ON r.query_id = p.query_id
    WHERE r.evaluation_date >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT 
    r.query_id,
    r.query_text,
    r.ndcg_at_10,
    p.total_duration_ms,
    (r.ndcg_at_10 - s.avg_ndcg) / s.stddev_ndcg as ndcg_z_score,
    (p.total_duration_ms - s.avg_duration) / s.stddev_duration as duration_z_score,
    r.evaluation_date
FROM rag_evaluation_results r
JOIN rag_performance_logs p ON r.query_id = p.query_id
CROSS JOIN performance_stats s
WHERE r.evaluation_date >= CURRENT_DATE - INTERVAL '24 hours'
  AND (
    ABS((r.ndcg_at_10 - s.avg_ndcg) / s.stddev_ndcg) > 2.5
    OR ABS((p.total_duration_ms - s.avg_duration) / s.stddev_duration) > 2.5
  )
ORDER BY ABS((r.ndcg_at_10 - s.avg_ndcg) / s.stddev_ndcg) DESC;

-- ======================
-- A/B TEST ANALYSIS
-- ======================

-- A/B Test Results Comparison
-- Compare control vs test group performance
WITH ab_test_stats AS (
    SELECT 
        test_group,
        COUNT(*) as num_queries,
        AVG(ndcg_at_10) as avg_ndcg,
        AVG(mrr) as avg_mrr,
        AVG(total_duration_ms) as avg_duration_ms,
        AVG(user_satisfaction_score) as avg_satisfaction,
        STDDEV(ndcg_at_10) as stddev_ndcg,
        STDDEV(mrr) as stddev_mrr
    FROM rag_ab_test_results
    WHERE test_start_date >= CURRENT_DATE - INTERVAL '14 days'
      AND test_group IN ('control', 'test')
    GROUP BY test_group
)
SELECT 
    control.num_queries as control_queries,
    test.num_queries as test_queries,
    control.avg_ndcg as control_avg_ndcg,
    test.avg_ndcg as test_avg_ndcg,
    (test.avg_ndcg - control.avg_ndcg) / control.avg_ndcg * 100 as ndcg_improvement_pct,
    control.avg_mrr as control_avg_mrr,
    test.avg_mrr as test_avg_mrr,
    (test.avg_mrr - control.avg_mrr) / control.avg_mrr * 100 as mrr_improvement_pct,
    control.avg_duration_ms as control_avg_duration_ms,
    test.avg_duration_ms as test_avg_duration_ms,
    (test.avg_duration_ms - control.avg_duration_ms) / control.avg_duration_ms * 100 as duration_change_pct,
    control.avg_satisfaction as control_satisfaction,
    test.avg_satisfaction as test_satisfaction,
    test.avg_satisfaction - control.avg_satisfaction as satisfaction_improvement
FROM ab_test_stats control
CROSS JOIN ab_test_stats test
WHERE control.test_group = 'control' 
  AND test.test_group = 'test';

-- Statistical Significance Test
-- T-test for A/B test results
WITH ab_test_data AS (
    SELECT 
        test_group,
        ndcg_at_10,
        ROW_NUMBER() OVER (PARTITION BY test_group ORDER BY query_id) as rn
    FROM rag_ab_test_results
    WHERE test_start_date >= CURRENT_DATE - INTERVAL '7 days'
      AND test_group IN ('control', 'test')
),
control_stats AS (
    SELECT 
        COUNT(*) as n_control,
        AVG(ndcg_at_10) as mean_control,
        VAR_POP(ndcg_at_10) as var_control
    FROM ab_test_data 
    WHERE test_group = 'control'
),
test_stats AS (
    SELECT 
        COUNT(*) as n_test,
        AVG(ndcg_at_10) as mean_test,
        VAR_POP(ndcg_at_10) as var_test
    FROM ab_test_data 
    WHERE test_group = 'test'
)
SELECT 
    c.n_control,
    t.n_test,
    c.mean_control,
    t.mean_test,
    t.mean_test - c.mean_control as mean_difference,
    SQRT((c.var_control / c.n_control) + (t.var_test / t.n_test)) as standard_error,
    (t.mean_test - c.mean_control) / SQRT((c.var_control / c.n_control) + (t.var_test / t.n_test)) as t_statistic,
    CASE 
        WHEN ABS((t.mean_test - c.mean_control) / SQRT((c.var_control / c.n_control) + (t.var_test / t.n_test))) > 1.96 
        THEN 'Statistically Significant (p < 0.05)'
        ELSE 'Not Significant'
    END as significance_95pct
FROM control_stats c
CROSS JOIN test_stats t;

-- ======================
-- EMBEDDING QUALITY ANALYSIS
-- ======================

-- Embedding Similarity Distribution
-- Analyze distribution of similarity scores in retrieval
SELECT 
    FLOOR(similarity_score * 10) / 10 as similarity_bucket,
    COUNT(*) as num_documents,
    COUNT(CASE WHEN is_relevant THEN 1 END) as num_relevant,
    COUNT(CASE WHEN is_relevant THEN 1 END)::float / COUNT(*) as precision_at_bucket,
    AVG(user_click_through) as avg_ctr
FROM document_retrieval_logs d
JOIN document_relevance_labels l ON d.document_id = l.document_id AND d.query_id = l.query_id
WHERE d.timestamp >= NOW() - INTERVAL '7 days'
GROUP BY FLOOR(similarity_score * 10) / 10
ORDER BY similarity_bucket DESC;

-- Query Type Performance Analysis
-- Performance breakdown by query categories
SELECT 
    query_category,
    COUNT(*) as num_queries,
    AVG(ndcg_at_10) as avg_ndcg,
    AVG(retrieval_duration_ms) as avg_retrieval_ms,
    AVG(rerank_duration_ms) as avg_rerank_ms,
    AVG(num_documents_retrieved) as avg_docs_retrieved,
    COUNT(CASE WHEN ndcg_at_10 > 0.8 THEN 1 END)::float / COUNT(*) as high_quality_rate
FROM rag_evaluation_results r
JOIN query_categories c ON r.query_id = c.query_id
WHERE r.evaluation_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY query_category
ORDER BY avg_ndcg DESC;

-- ======================
-- COST ANALYSIS
-- ======================

-- Cost per Query Analysis
-- Calculate costs based on compute time and model usage
WITH cost_analysis AS (
    SELECT 
        DATE_TRUNC('day', timestamp) as day,
        COUNT(*) as num_queries,
        AVG(embedding_compute_ms) as avg_embedding_ms,
        AVG(rerank_compute_ms) as avg_rerank_ms,
        SUM(embedding_compute_ms) / 1000.0 / 3600.0 as total_embedding_hours,
        SUM(rerank_compute_ms) / 1000.0 / 3600.0 as total_rerank_hours
    FROM rag_performance_logs
    WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE_TRUNC('day', timestamp)
)
SELECT 
    day,
    num_queries,
    avg_embedding_ms,
    avg_rerank_ms,
    total_embedding_hours,
    total_rerank_hours,
    -- Assuming $0.50/hour for GPU compute
    (total_embedding_hours + total_rerank_hours) * 0.50 as estimated_daily_cost,
    ((total_embedding_hours + total_rerank_hours) * 0.50) / num_queries as cost_per_query
FROM cost_analysis
ORDER BY day DESC;

-- ======================
-- SYSTEM HEALTH MONITORING
-- ======================

-- Error Rate Analysis
-- Monitor system errors and failure modes
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'success' THEN 1 END) as successful_requests,
    COUNT(CASE WHEN status = 'error' THEN 1 END) as error_requests,
    COUNT(CASE WHEN status = 'timeout' THEN 1 END) as timeout_requests,
    COUNT(CASE WHEN status = 'error' THEN 1 END)::float / COUNT(*) as error_rate,
    COUNT(CASE WHEN status = 'timeout' THEN 1 END)::float / COUNT(*) as timeout_rate
FROM rag_request_logs
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour DESC;

-- Resource Utilization
-- Monitor GPU and CPU usage patterns
SELECT 
    DATE_TRUNC('minute', timestamp) as minute,
    AVG(gpu_utilization_percent) as avg_gpu_utilization,
    MAX(gpu_utilization_percent) as max_gpu_utilization,
    AVG(gpu_memory_used_gb) as avg_gpu_memory_gb,
    MAX(gpu_memory_used_gb) as max_gpu_memory_gb,
    AVG(cpu_utilization_percent) as avg_cpu_utilization,
    AVG(memory_used_gb) as avg_memory_gb,
    COUNT(*) as num_samples
FROM system_resource_logs
WHERE timestamp >= NOW() - INTERVAL '4 hours'
  AND component = 'rag_pipeline'
GROUP BY DATE_TRUNC('minute', timestamp)
ORDER BY minute DESC
LIMIT 60;
