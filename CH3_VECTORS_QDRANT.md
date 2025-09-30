# Chapter 3 — Optional Vectors (Qdrant) decision & indexing policy

## Decision Summary
For the MVP, we're using pgvector-only co-located with Postgres for handling fewer than 1 million vectors. For scale-out scenarios, we'll transition to Qdrant with separate collections per tenant or per corpus. The cutover will be gated by recall/latency metrics and corpus size thresholds.

## Why this split
The pgvector approach offers the simplest implementation with ACID guarantees and single database operations. Qdrant provides better latency and throughput at higher cardinality, supports hybrid search capabilities, and offers flexible payload filters for complex queries.

## Data model mapping
The Postgres source tables include messages and optionally rag_chunks. Qdrant payload fields will contain id, tenant_id, doc_type, pii_flags, retention_category, legal_hold, source_table, source_pk, and created_at. The vector field will be named embedding with placeholder dimensions to be set in Chapter 4.

## Indexing policy
We'll upsert on create and update operations, use soft-delete flags first, then hard-delete during retention jobs. Deduplication will be handled by the combination of tenant_id, source_table, and source_pk. The refresh cadence will be near-real-time for messages and use batch windows for bulk corpora.

## HNSW & search parameters (initial targets)
Initial HNSW configuration will use M=16 and ef_construct=128, with tuning to follow. Search ef will be set to 128, tuned per latency and recall targets. Distance metric will be cosine. SLO targets for MVP data include Recall@10 ≥ 0.95 and p95 search latency ≤ 150 ms at 1k QPS for small corpus.

## Privacy & compliance hooks
PII flags will be stored in payload with allow-list queries and blocking of disallowed doc_types for HR PII by region. Records with legal_hold=true will prevent deletion and purge operations, while retention_category drives TTL jobs. Redaction will occur pre-index with names, emails, and IDs masked where policy requires.

## Sync & consistency
Postgres will remain the source-of-truth for row versions. We'll use CDC-style streaming or periodic diff jobs for create, update, and delete propagation to Qdrant. Idempotent upserts will handle changes, tombstones will manage deletes, and reconciliation jobs will emit audit reports.

## Failure modes & recovery
If Qdrant becomes unavailable, we'll fall back to the pgvector path only. A mismatch detector will identify count-by-tenant differences and reconcile on schedule. The corruption playbook involves exporting payloads by tenant and rebuilding collections.

## Observability & cost
We'll emit metrics for queries per second, p95 latency, recall sample scores, failures, and rebuild time. Cost knobs include ef settings, batch size, filter selectivity, and shard/collection strategy by tenant size.

## Done-when
The qdrant_mapping.yaml and sync_plan.md files exist, PROJECT_STATUS shows Chapter 3 checked, and DECISIONS.log has a new timestamped entry for Chapter 3.