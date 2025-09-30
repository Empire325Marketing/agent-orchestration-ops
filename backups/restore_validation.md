# Restore Validation — Plan (MVP)

## Purpose
Prove backups are restorable and consistent; catch drift, permission, or retention gaps.

## Flow (daily)
1) Allocate isolated sandbox (network-off; see Ch.6).
2) Restore latest Postgres base backup + replay WAL to RPO target.
3) Run smoke SQL:
   - table counts, FK checks (sample), vector index availability
   - retention/legal_hold flags present (see Ch.9)
4) Produce report (pass/fail + timings) and store under `/srv/primarch/backups/reports/`.
5) Append a single line to `DECISIONS.log` with result + timestamp (manual for MVP).

## Acceptance criteria
- Restore completes within RTO goals.
- Integrity checks pass.
- No PII is exposed outside sandbox.
