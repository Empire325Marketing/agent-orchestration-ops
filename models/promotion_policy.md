# Model Promotion Policy
Stages: experimental → shadow (read-only) → canary (10%) → production (100%).
Requirements: pass Readiness Gate, Safety Gate, and Supply Chain attestations.
Evidence: eval report, safety report, perf/cost snapshot, signed provenance.
Rollback: automatic on burn/p95/error/safety/cost triggers; manual override requires DECISIONS entry.
