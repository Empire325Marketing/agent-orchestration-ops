# Runbook — Region Cutover (Planned)
1) Freeze writes for affected tenants.
2) Export + verify in source region (Ch.25).
3) Restore/import to target region; validate contracts (Ch.16).
4) Update tenant region mapping; warm caches.
5) Unfreeze; verify SLOs; append DECISIONS.log.
