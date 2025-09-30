-- =====================================================
-- RAG 2.0 Hybrid Search Queries for PostgreSQL + pgvector
-- =====================================================
-- Purpose: Production-ready SQL queries for hybrid BM25 + vector search
-- Target: p95 retrieval latency ≤ 150ms
-- Author: Primarch RAG Team
-- Date: 2025-09-30
-- =====================================================

-- =====================================================
-- SCHEMA SETUP
-- =====================================================

-- Create the main documents table with hybrid search capabilities
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    embedding vector(768),  -- 768-dimensional embeddings for optimal performance
    content_tsvector tsvector,  -- Full-text search vector
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    source_type VARCHAR(50),  -- 'pdf', 'code', 'markdown', etc.
    source_path TEXT,
    chunk_index INTEGER DEFAULT 0,
    parent_document_id UUID REFERENCES documents(id)
);

-- =====================================================
-- INDEX CREATION FOR OPTIMAL PERFORMANCE
-- =====================================================

-- HNSW index for vector similarity search (primary performance driver)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documents_embedding_hnsw 
ON documents USING hnsw (embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- GIN index for full-text search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documents_fts_gin 
ON documents USING gin(content_tsvector);

-- Supporting indexes for metadata filtering
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documents_source_type 
ON documents(source_type) WHERE source_type IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documents_created_at 
ON documents(created_at);

-- Partial index for non-null embeddings (memory optimization)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documents_embedding_partial
ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64)
WHERE embedding IS NOT NULL;

-- =====================================================
-- QUERY PERFORMANCE CONFIGURATION
-- =====================================================

-- Optimal pgvector parameters for <150ms latency
SET hnsw.ef_search = 40;  -- Balance between recall and latency
SET max_parallel_workers_per_gather = 4;
SET work_mem = '256MB';
SET effective_cache_size = '8GB';

-- =====================================================
-- TRIGGER FOR AUTOMATIC TSVECTOR UPDATES
-- =====================================================

-- Automatically maintain tsvector when content changes
CREATE OR REPLACE FUNCTION update_content_tsvector() RETURNS trigger AS $$
BEGIN
    NEW.content_tsvector := to_tsvector('english', 
        COALESCE(NEW.title, '') || ' ' || COALESCE(NEW.content, '')
    );
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_content_tsvector 
    BEFORE INSERT OR UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_content_tsvector();

-- =====================================================
-- CORE HYBRID SEARCH FUNCTIONS
-- =====================================================

-- Function to calculate Reciprocal Rank Fusion (RRF) score
CREATE OR REPLACE FUNCTION rrf_score(rank_position INTEGER, k INTEGER DEFAULT 60)
RETURNS FLOAT AS $$
BEGIN
    RETURN 1.0 / (k + rank_position);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- HYBRID SEARCH QUERIES
-- =====================================================

-- Query 1: Basic Hybrid Search with RRF Fusion
-- Description: Combines BM25 and vector search using RRF
-- Expected Performance: <100ms for 1M documents
WITH vector_search AS (
    SELECT 
        id,
        title,
        content,
        metadata,
        1 - (embedding <=> $1::vector) as similarity_score,
        ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) as vector_rank
    FROM documents 
    WHERE embedding IS NOT NULL
    ORDER BY embedding <=> $1::vector
    LIMIT 100
),
bm25_search AS (
    SELECT 
        id,
        title, 
        content,
        metadata,
        ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) as bm25_score,
        ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) DESC) as bm25_rank
    FROM documents
    WHERE content_tsvector @@ plainto_tsquery('english', $2)
    ORDER BY ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) DESC
    LIMIT 100
),
rrf_fusion AS (
    SELECT 
        COALESCE(v.id, b.id) as id,
        COALESCE(v.title, b.title) as title,
        COALESCE(v.content, b.content) as content,
        COALESCE(v.metadata, b.metadata) as metadata,
        COALESCE(v.similarity_score, 0) as vector_score,
        COALESCE(b.bm25_score, 0) as bm25_score,
        rrf_score(COALESCE(v.vector_rank, 999999)) + rrf_score(COALESCE(b.bm25_rank, 999999)) as rrf_score
    FROM vector_search v
    FULL OUTER JOIN bm25_search b ON v.id = b.id
)
SELECT 
    id,
    title,
    content,
    metadata,
    vector_score,
    bm25_score,
    rrf_score,
    ROW_NUMBER() OVER (ORDER BY rrf_score DESC) as final_rank
FROM rrf_fusion
ORDER BY rrf_score DESC
LIMIT $3;  -- Usually 20 for reranking

-- Query 2: Filtered Hybrid Search with Source Type
-- Description: Hybrid search with document type filtering
-- Use Case: Search within specific document types (e.g., only PDFs)
WITH vector_search AS (
    SELECT 
        id, title, content, metadata, source_type,
        1 - (embedding <=> $1::vector) as similarity_score,
        ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) as vector_rank
    FROM documents 
    WHERE embedding IS NOT NULL 
    AND source_type = ANY($4::text[])  -- ['pdf', 'code', 'markdown']
    ORDER BY embedding <=> $1::vector
    LIMIT 100
),
bm25_search AS (
    SELECT 
        id, title, content, metadata, source_type,
        ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) as bm25_score,
        ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) DESC) as bm25_rank
    FROM documents
    WHERE content_tsvector @@ plainto_tsquery('english', $2)
    AND source_type = ANY($4::text[])
    ORDER BY ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) DESC
    LIMIT 100
)
SELECT 
    COALESCE(v.id, b.id) as id,
    COALESCE(v.title, b.title) as title,
    COALESCE(v.content, b.content) as content,
    COALESCE(v.source_type, b.source_type) as source_type,
    rrf_score(COALESCE(v.vector_rank, 999999)) + rrf_score(COALESCE(b.bm25_rank, 999999)) as rrf_score
FROM vector_search v
FULL OUTER JOIN bm25_search b ON v.id = b.id
ORDER BY rrf_score DESC
LIMIT $3;

-- Query 3: Time-Bounded Hybrid Search
-- Description: Search within specific time ranges (for recent documents)
-- Performance: Uses created_at index for efficient filtering
WITH recent_docs AS (
    SELECT id FROM documents 
    WHERE created_at >= $4::timestamp  -- Recent documents only
),
vector_search AS (
    SELECT 
        d.id, d.title, d.content, d.metadata, d.created_at,
        1 - (d.embedding <=> $1::vector) as similarity_score,
        ROW_NUMBER() OVER (ORDER BY d.embedding <=> $1::vector) as vector_rank
    FROM documents d
    INNER JOIN recent_docs r ON d.id = r.id
    WHERE d.embedding IS NOT NULL
    ORDER BY d.embedding <=> $1::vector
    LIMIT 100
),
bm25_search AS (
    SELECT 
        d.id, d.title, d.content, d.metadata, d.created_at,
        ts_rank_cd(d.content_tsvector, plainto_tsquery('english', $2)) as bm25_score,
        ROW_NUMBER() OVER (ORDER BY ts_rank_cd(d.content_tsvector, plainto_tsquery('english', $2)) DESC) as bm25_rank
    FROM documents d
    INNER JOIN recent_docs r ON d.id = r.id
    WHERE d.content_tsvector @@ plainto_tsquery('english', $2)
    ORDER BY ts_rank_cd(d.content_tsvector, plainto_tsquery('english', $2)) DESC
    LIMIT 100
)
SELECT 
    COALESCE(v.id, b.id) as id,
    COALESCE(v.title, b.title) as title,
    COALESCE(v.content, b.content) as content,
    COALESCE(v.created_at, b.created_at) as created_at,
    rrf_score(COALESCE(v.vector_rank, 999999)) + rrf_score(COALESCE(b.bm25_rank, 999999)) as rrf_score
FROM vector_search v
FULL OUTER JOIN bm25_search b ON v.id = b.id
ORDER BY rrf_score DESC
LIMIT $3;

-- Query 4: Metadata-Enhanced Hybrid Search
-- Description: Incorporates JSONB metadata in search scoring
-- Use Case: Boost results based on document metadata (tags, categories, etc.)
WITH vector_search AS (
    SELECT 
        id, title, content, metadata,
        1 - (embedding <=> $1::vector) as similarity_score,
        ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) as vector_rank,
        CASE 
            WHEN metadata->>'category' = $4 THEN 1.2  -- Category boost
            WHEN metadata->>'priority' = 'high' THEN 1.1  -- Priority boost
            ELSE 1.0
        END as metadata_boost
    FROM documents 
    WHERE embedding IS NOT NULL
    ORDER BY embedding <=> $1::vector
    LIMIT 100
),
bm25_search AS (
    SELECT 
        id, title, content, metadata,
        ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) as bm25_score,
        ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) DESC) as bm25_rank,
        CASE 
            WHEN metadata->>'category' = $4 THEN 1.2
            WHEN metadata->>'priority' = 'high' THEN 1.1
            ELSE 1.0
        END as metadata_boost
    FROM documents
    WHERE content_tsvector @@ plainto_tsquery('english', $2)
    ORDER BY ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) DESC
    LIMIT 100
)
SELECT 
    COALESCE(v.id, b.id) as id,
    COALESCE(v.title, b.title) as title,
    COALESCE(v.content, b.content) as content,
    (rrf_score(COALESCE(v.vector_rank, 999999)) + rrf_score(COALESCE(b.bm25_rank, 999999))) 
        * COALESCE(v.metadata_boost, b.metadata_boost, 1.0) as boosted_rrf_score
FROM vector_search v
FULL OUTER JOIN bm25_search b ON v.id = b.id
ORDER BY boosted_rrf_score DESC
LIMIT $3;

-- =====================================================
-- PERFORMANCE ANALYSIS QUERIES
-- =====================================================

-- Query Performance Analysis
-- Shows query execution statistics for optimization
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
WITH vector_search AS (
    SELECT id, embedding <=> $1::vector as distance
    FROM documents 
    WHERE embedding IS NOT NULL
    ORDER BY embedding <=> $1::vector
    LIMIT 100
)
SELECT * FROM vector_search;

-- Index Usage Statistics  
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes 
WHERE tablename = 'documents'
ORDER BY idx_scan DESC;

-- Query to check HNSW index build progress
SELECT 
    indexname,
    phase,
    tuples_total,
    tuples_done,
    (tuples_done::float / tuples_total * 100) as percent_complete
FROM pg_stat_progress_create_index
WHERE indexname = 'idx_documents_embedding_hnsw';

-- =====================================================
-- CACHE-OPTIMIZED QUERIES
-- =====================================================

-- Query 5: Cache-Friendly Hybrid Search
-- Description: Optimized for frequent similar queries with prepared statements
PREPARE hybrid_search_cached(vector(768), text, integer) AS
WITH vector_search AS (
    SELECT 
        id, title, content,
        1 - (embedding <=> $1) as similarity_score,
        ROW_NUMBER() OVER (ORDER BY embedding <=> $1) as vector_rank
    FROM documents 
    WHERE embedding IS NOT NULL
    ORDER BY embedding <=> $1
    LIMIT 100
),
bm25_search AS (
    SELECT 
        id, title, content,
        ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) as bm25_score,
        ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) DESC) as bm25_rank
    FROM documents
    WHERE content_tsvector @@ plainto_tsquery('english', $2)
    ORDER BY ts_rank_cd(content_tsvector, plainto_tsquery('english', $2)) DESC
    LIMIT 100
)
SELECT 
    COALESCE(v.id, b.id) as id,
    COALESCE(v.title, b.title) as title,
    COALESCE(v.content, b.content) as content,
    rrf_score(COALESCE(v.vector_rank, 999999)) + rrf_score(COALESCE(b.bm25_rank, 999999)) as rrf_score
FROM vector_search v
FULL OUTER JOIN bm25_search b ON v.id = b.id
ORDER BY rrf_score DESC
LIMIT $3;

-- =====================================================
-- MONITORING AND MAINTENANCE QUERIES
-- =====================================================

-- Check vector index statistics
SELECT 
    n_distinct,
    n_dead_tup,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    last_vacuum,
    last_autovacuum,
    last_analyze
FROM pg_stat_user_tables 
WHERE relname = 'documents';

-- Monitor query performance over time
CREATE TABLE IF NOT EXISTS query_performance_log (
    query_id UUID DEFAULT gen_random_uuid(),
    query_type VARCHAR(50),
    execution_time_ms FLOAT,
    result_count INTEGER,
    executed_at TIMESTAMP DEFAULT NOW()
);

-- Function to log query performance
CREATE OR REPLACE FUNCTION log_query_performance(
    p_query_type VARCHAR(50),
    p_execution_time_ms FLOAT,
    p_result_count INTEGER
) RETURNS VOID AS $$
BEGIN
    INSERT INTO query_performance_log (query_type, execution_time_ms, result_count)
    VALUES (p_query_type, p_execution_time_ms, p_result_count);
END;
$$ LANGUAGE plpgsql;

-- Performance monitoring query
SELECT 
    query_type,
    COUNT(*) as query_count,
    AVG(execution_time_ms) as avg_execution_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY execution_time_ms) as p95_execution_time,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY execution_time_ms) as p99_execution_time,
    AVG(result_count) as avg_result_count
FROM query_performance_log
WHERE executed_at > NOW() - INTERVAL '24 hours'
GROUP BY query_type
ORDER BY avg_execution_time DESC;

-- =====================================================
-- BATCH OPERATIONS FOR DATA INGESTION
-- =====================================================

-- Optimized batch insert for documents with embeddings
CREATE OR REPLACE FUNCTION batch_insert_documents(
    p_documents JSONB
) RETURNS INTEGER AS $$
DECLARE
    inserted_count INTEGER;
BEGIN
    WITH document_data AS (
        SELECT 
            (doc->>'title')::TEXT as title,
            (doc->>'content')::TEXT as content,
            (doc->>'metadata')::JSONB as metadata,
            (doc->>'embedding')::TEXT::vector(768) as embedding,
            (doc->>'source_type')::TEXT as source_type,
            (doc->>'source_path')::TEXT as source_path
        FROM jsonb_array_elements(p_documents) as doc
    )
    INSERT INTO documents (title, content, metadata, embedding, source_type, source_path)
    SELECT title, content, metadata, embedding, source_type, source_path
    FROM document_data;
    
    GET DIAGNOSTICS inserted_count = ROW_COUNT;
    RETURN inserted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- CLEANUP AND MAINTENANCE
-- =====================================================

-- Vacuum and analyze for optimal performance (run periodically)
VACUUM ANALYZE documents;

-- Reindex if performance degrades
REINDEX INDEX CONCURRENTLY idx_documents_embedding_hnsw;
REINDEX INDEX CONCURRENTLY idx_documents_fts_gin;

-- Remove old performance logs (cleanup job)
DELETE FROM query_performance_log 
WHERE executed_at < NOW() - INTERVAL '7 days';

-- =====================================================
-- EXAMPLE USAGE
-- =====================================================

/*
Example 1: Basic hybrid search
SELECT * FROM hybrid_search_query(
    '[0.1, 0.2, ..., 0.768]'::vector(768),  -- Query embedding
    'machine learning algorithms',           -- Search text
    20                                      -- Top K results
);

Example 2: Filtered search by document type
SELECT * FROM filtered_hybrid_search(
    '[0.1, 0.2, ..., 0.768]'::vector(768),  -- Query embedding
    'neural networks',                       -- Search text  
    20,                                     -- Top K results
    ARRAY['pdf', 'arxiv']                   -- Source types
);

Example 3: Execute prepared statement
EXECUTE hybrid_search_cached(
    '[0.1, 0.2, ..., 0.768]'::vector(768),
    'deep learning',
    20
);
*/

-- =====================================================
-- PERFORMANCE TUNING RECOMMENDATIONS
-- =====================================================

/*
1. HNSW Index Tuning:
   - Increase ef_search for higher recall (trade-off: higher latency)
   - Adjust m parameter during index creation for memory vs accuracy
   - Monitor index build time and query performance

2. Full-Text Search Optimization:
   - Use custom dictionaries for domain-specific terms
   - Adjust ts_rank_cd parameters for better relevance
   - Consider phrase searching for exact matches

3. Query Optimization:
   - Use EXPLAIN ANALYZE to identify bottlenecks
   - Monitor buffer hit ratios
   - Consider query result caching for frequent searches
   - Use connection pooling for concurrent queries

4. Hardware Recommendations:
   - Ensure sufficient RAM to keep indexes in memory
   - SSD storage for better I/O performance
   - Consider read replicas for high query volume

5. Maintenance Schedule:
   - VACUUM ANALYZE weekly
   - REINDEX monthly or when performance degrades
   - Monitor query performance logs daily
   - Update table statistics regularly
*/