# Chapter 8 — Secrets & IAM

## Decision Summary
Vault serves as the KMS and secrets store with least-privilege access controls. Default rotation periods are set to 90 days with service-specific adjustments. Break-glass procedures require dual-approval and are time-boxed to 24 hours with full audit logging.

## Scope
The secrets management scope encompasses API keys for external services, database credentials for Postgres and vector stores, model credentials for LLM runtime authentication, and proxy credentials for egress control. All secrets are centrally managed through Vault with role-based access controls.

## Non-goals
Hardware HSM configuration is excluded from the MVP scope to reduce complexity. Production PKI certificate issuance is handled separately from this secrets management system. These capabilities can be added post-MVP based on security requirements.