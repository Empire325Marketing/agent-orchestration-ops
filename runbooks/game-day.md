# Runbook — Game Day: Backup & DR

## Cadence
- Monthly, 2 hours, cross-functional (SRE + Platform + Compliance).

## Exercises
- Timed Postgres restore to sandbox, target RTO.
- Simulated Vault policy loss (restore metadata).
- CI artifact provenance re-hydrate (read-only).

## Outcomes
- Record timings, issues, follow-ups.
- Append a DECISIONS.log entry tagged `gameday_backups`.
