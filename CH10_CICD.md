# Chapter 10 — CI/CD Guardrails

## Decision Summary
- **Canary deployment**: 10% traffic with automatic rollback on SLO violations
- **Branch protection**: Main branch protected with required reviews and checks
- **Supply chain security**: SBOM generation, image signing, provenance attestation
- **Release gates**: Integration with observability metrics and cost controls
- **Artifact retention**: 90-day retention for compliance and audit requirements

## CI/CD Goals
- Automated quality gates to prevent regression
- Observable deployments with metric-based rollback
- Secure software supply chain with attestations
- Compliance-ready audit trail for all releases
- Integration with existing platform components

## Non-Goals
- Multi-region deployment coordination (deferred to Chapter 14)
- Blue/green deployments (canary sufficient for MVP)
- Advanced feature flags (simple on/off sufficient)
- Custom deployment strategies beyond canary

## Integration Points

### Chapter 7 — Observability Integration
- **Burn-rate gates**: Deployments blocked if error budget burn >2× in 30 minutes
- **SLO monitoring**: p95 latency and error rate thresholds for rollback decisions
- **Metrics validation**: Pre-deployment dashboard health checks required
- **Alert coordination**: Deployment events tagged in observability system

### Chapter 8 — Secrets & IAM Integration
- **Signed artifacts**: All container images signed with Vault-managed keys
- **Attestation storage**: Provenance stored in Vault with 90-day retention
- **Pipeline authentication**: Service accounts for CI/CD operations
- **Key rotation**: Signing keys follow 30-day rotation schedule

### Chapter 9 — Compliance Integration
- **Audit trail**: All deployment actions logged to DECISIONS.log
- **SBOM generation**: Software bill of materials for compliance reporting
- **Vulnerability scanning**: Required before any production deployment
- **Retention policy**: Deployment artifacts retained per compliance matrix

## Architecture Overview
Three-pipeline approach:
1. **Verify Pipeline**: PR validation (lint, test, build)
2. **Release Pipeline**: Canary deployment with automatic promotion/rollback
3. **Security Pipeline**: SBOM, vulnerability scanning, signing, provenance

## Cross-References
- Pipeline definitions: cicd/pipelines.md
- Branch and approval policies: cicd/policy.md
- Canary rollout rules: cicd/canary_rollout.md
- Supply chain security: cicd/supply_chain.md
- Release readiness: release_readiness.md