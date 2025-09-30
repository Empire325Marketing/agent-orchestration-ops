# Lineage Validation (Manual MVP)
- Verify each edge in `lineage_graph.yaml` has corresponding producers/consumers and contracts.
- During restore validation (Ch.15), run `sql/dq_checks.sql` and capture results.
- Ensure legal_hold and retention hooks still apply post-restore (Ch.9).
