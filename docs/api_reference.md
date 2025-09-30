# API Reference (MVP Skeleton)

## POST /v1/assist
- Body: { "input": string, "tools": [string], "session": string? }
- Returns: { "output": string, "trace_id": string, "tokens": {…} }

## GET /v1/health
- Returns: { "status": "ok", "ts": "<iso8601>" }

> NOTE: Replace with generated reference when OpenAPI spec is finalized (Ch.5 tool registry).
