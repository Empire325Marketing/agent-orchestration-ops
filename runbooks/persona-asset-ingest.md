# Runbook — Persona Asset Ingest (FRANK)
1) Place/update files in `/mnt/data` (see manifest).
2) Re-run Chapter 28 to update checksums and report.
3) Review `personas/frank/ingest_report.md` for gaps.
4) Run safety tests (Ch.17); if deltas, trigger CI safety gates (Ch.10/26).
5) Append DECISIONS.log with action and results.