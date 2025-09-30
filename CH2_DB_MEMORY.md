# Chapter 2 — DB-as-Memory, Retention & Deletion

## Purpose
Postgres is the single source-of-truth for sessions, messages, tools, and tool invocations. It also stores vector embeddings via pgvector for small-to-medium corpora. Qdrant remains optional for higher-scale vector search.

## Logical Schema (narrative, no SQL)
- sessions: per conversation; fields: id, user_id, tenant_id, created_at, metadata (JSON).
- messages: child of sessions; fields: id, session_id, role, content (JSON), created_at, embedding (vector).
- tools: registry of callable tools; fields: id, name, spec (JSON).
- tool_invocations: audit log of tool calls; fields: id, message_id, tool_name, args (JSON), result (JSON), status, created_at.
- rag_chunks (optional): external knowledge snippets; fields: id, session_id?, content, embedding (vector), metadata (JSON).

## Embedding Dimensions
Embedding vector dims are driven by the chosen model. Placeholder defaults: 1536 (OpenAI-like) or 1024 (BGE-like). The exact value will be set in Chapter 4 when embeddings are finalized.

## Vector Strategy
- pgvector path: simplest for MVP; ACID, co-located with OLTP; suitable < 1M vectors.
- Qdrant path: performance/scale; maintain a mapping doc and a one-way sync plan from Postgres IDs to Qdrant point IDs.

## Retention & Deletion Integration
Retention is enforced by automated jobs driven by the retention_matrix.yaml. Deletions produce proof artifacts (CSV/JSON audit logs) and honor legal holds before erasure.

## Legal Holds & DSR
Records tagged with legal_hold=true are excluded from deletion until cleared. Data Subject Requests (DSR) follow a documented checklist to locate, review, minimize, and erase where lawful.

## Done-when
- Retention matrix YAML exists with initial categories.
- Deletion, legal-hold, and DSR runbooks exist as text.
- Chapter 2 is marked checked in PROJECT_STATUS.md.