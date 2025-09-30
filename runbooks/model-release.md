# Runbook — Model Release
1) Prepare: finalize eval + safety reports; ensure attestations exist.
2) Shadow: route read-only traffic; compare vs baseline for 24–72h.
3) Canary: 10% with auto-rollback rules (Ch.10).
4) Promote: 100% if gates pass; notify; capture audit refs.
5) Post: create/update Model Card; append DECISIONS with links.
