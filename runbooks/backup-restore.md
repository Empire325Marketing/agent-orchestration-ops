# Runbook — Backup & Restore (MVP)

## Backup (operator)
- Ensure schedules in `backups/backup_matrix.yaml` are followed by your scheduler.
- Monitor backup freshness alerts (see `observability/backup_alerts.prom`).
- On failure: retry once; escalate to SRE; file DECISIONS.log entry.

## Restore (operator)
1) Declare incident (severity from `runbooks/incident.md`).
2) Choose restore point (closest ≤ RPO).
3) Restore to sandbox first; validate with `backups/restore_validation.md`.
4) Announce maintenance; restore to prod; verify; reopen traffic.
5) Postmortem + update DECISIONS.log.
