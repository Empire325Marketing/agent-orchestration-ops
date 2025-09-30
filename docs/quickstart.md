# Quickstart — Hello, Tools

Goal: DB-as-memory → tool call → response (local).

1) Seed a sample memory row in Postgres (see Chapter 2 schema).
2) Call the orchestrator route `/v1/assist` with a simple prompt.
3) Observe traces in OTel (Chapter 7) and verify latency SLOs.
4) Troubleshoot via `troubleshooting.md` if errors occur.
