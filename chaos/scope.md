# Chaos Scope & Guardrails
- Environments: shadow → canary, never full prod by default
- Blast radius: ≤10% traffic; opt-out for HR PII routes (Ch.30)
- Change control: CI-triggered with approvals (Ch.10)
- Observability: traces tagged `chaos_experiment_id`
- Rollback: automatic per readiness gates (Ch.13)
