# Sync Plan — Postgres → Qdrant (optional)

## Sources
- messages (embedding optional per row)
- rag_chunks (embedding required)

## Identifiers
- Qdrant point id = `${source_table}:${source_pk}`

## Flow
1) Capture changes (insert/update/delete) from Postgres.
2) Map to Qdrant payload and embedding dims.
3) Upsert point on insert/update; soft-delete on delete; hard-delete on confirmed purge.
4) Reconciliation job runs daily: compare counts and sample rows; repair differences.
5) Emit audit artifacts (CSV/JSON) with timestamps and counts.

## Error handling
- On Qdrant failure, queue retries with backoff; fallback to pgvector-only search.

## Security & compliance
- Apply pii_flags and legal_hold before upsert.
- Enforce region blocklists for HR PII queries.