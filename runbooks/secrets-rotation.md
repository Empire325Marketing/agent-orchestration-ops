# Runbook — Secrets Rotation (Vault)
1) Rotate at policy cadence (API keys 30d, DB creds 60d).
2) Update tool_registry.yaml secrets_path references if paths change.
3) Verify successful rotation via canary calls; roll back if failures exceed threshold.
4) Log rotation event with operator initials and affected tools.