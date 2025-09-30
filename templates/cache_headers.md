# Client Cache Headers (Guidance)
- Prefer `ETag` with strong validators for deterministic responses.
- Use `Cache-Control: max-age=<ttl>, public` only for non-PII, read-only endpoints.
- Support `If-None-Match` on GET where safe.
