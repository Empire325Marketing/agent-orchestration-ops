# Caching Policy
Layers: in-process memory → local disk (optional) → egress HTTP cache.
Do not cache:
- Requests with `pii_flags=true` or HR PII class (Ch.30)
- Authenticated user-specific responses without stable ETags
- Safety/red-team routes, admin routes

Keying Strategy:
`cache:{tenant}:{route}:{model}:{tool}:{input_hash}:{params_hash}:{schema_ver}`
TTLs:
- `/v1/assist` (deterministic prompts only): 60s
- Tool: `search_web` read-only: 300s
- Embeddings: 7d (by normalized text hash + dim + model)
- Health/metadata: 30s

Invalidation Triggers:
- Data contract version bump (Ch.16)
- Model or persona change (Ch.26/35)
- Legal hold or deletion event (Ch.9): purge affected keys
