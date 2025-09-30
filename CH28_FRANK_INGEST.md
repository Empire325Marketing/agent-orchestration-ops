# Chapter 28 — FRANK Persona Asset Ingestion & Verification

## Scope
Ingest FRANK persona assets, record checksums & provenance, wire observability and a readiness gate.
Binaries remain under `/mnt/data`; `/srv/primarch` stores only text manifests/reports.

## Inventory
See `personas/FRANK_MANIFEST.md` for filename, path, SHA256, bytes, type, and presence.

## Method
- Discover files in `/mnt/data`
- Compute SHA256 + sizes
- Write manifest and ingest report
- Keep binaries in place; docs reference them

## Ties
- Ch.17 Safety Red-Teaming
- Ch.26 Prompt Firewall & Personas
- Ch.22 Docs (authoring guidance)

## Next steps
- Populate missing assets and re-run
- Run safety regression tests post-change