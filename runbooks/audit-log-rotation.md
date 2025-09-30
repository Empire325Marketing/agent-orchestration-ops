# Runbook — Audit Log Rotation & Retention
1) Rotate daily partitions; write anchor for the closed partition.
2) Verify anchor signature (if enabled).
3) Apply retention: hot/warm windows (see audit/log_schema.yaml) and legal-hold overrides (Ch.9).
4) Validate backups include closed partitions (Ch.15).
5) Record rotation summary and anchor hashes; append DECISIONS.log.
