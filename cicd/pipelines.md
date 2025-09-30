# CI/CD Pipelines

## 1. Verify Pipeline (Pull Request Validation)

### Triggers
- Pull request opened/updated to main branch
- Manual trigger for testing branches

### Steps
1. **Code Quality**
   - Lint check (language-specific linters)
   - Code formatting validation
   - Security static analysis (SAST)
   - Dependency vulnerability scan

2. **Testing**
   - Unit tests with coverage >80%
   - Integration tests against test database
   - API contract tests
   - Load test simulation (lightweight)

3. **Build Validation**
   - Container image build
   - Artifact packaging
   - Basic smoke tests on built artifacts

### Gates
- All tests pass (no flaky test tolerance)
- Security scan shows no critical vulnerabilities
- Coverage thresholds met
- Build artifacts successfully created

### Duration Target
- Complete pipeline: <15 minutes
- Fast feedback on common failures within 5 minutes

## 2. Release Pipeline (Canary Deployment)

### Triggers
- Merge to main branch (after Verify pipeline success)
- Manual promotion trigger for hotfixes

### Steps
1. **Pre-Deployment**
   - Build and tag production images
   - Run security pipeline (SBOM, signing)
   - Validate target environment health
   - Check observability dashboard baseline

2. **Canary Deployment (10% Traffic)**
   - Deploy to canary environment
   - Route 10% of traffic to new version
   - Monitor SLO metrics for 30 minutes
   - Automated health checks every 5 minutes

3. **Promotion Decision**
   - **Auto-promote** if all SLOs maintained
   - **Auto-rollback** if any trigger condition met
   - **Manual override** available for operators

4. **Full Deployment**
   - Gradually increase traffic: 10% → 25% → 50% → 100%
   - 5-minute observation window at each stage
   - Complete rollout or rollback within 20 minutes

### SLO Monitoring
- P95 latency regression <20%
- Error rate increase <1.5× baseline
- Error budget burn rate <2× normal
- Cost anomaly detection (Chapter 12 integration)

## 3. Security Pipeline (Supply Chain)

### Triggers
- Runs parallel to Release pipeline
- Can be triggered independently for security audits

### Steps
1. **SBOM Generation**
   - Scan all dependencies and versions
   - Generate SPDX-format bill of materials
   - Store SBOM with image tags

2. **Vulnerability Assessment**
   - Container image vulnerability scan
   - Dependency vulnerability analysis
   - License compliance check
   - Policy violation detection

3. **Image Signing**
   - Sign container images with Vault-managed keys
   - Generate cosign signatures
   - Store signatures in container registry

4. **Provenance Attestation**
   - Generate in-toto attestation
   - Include build environment details
   - Store provenance in Vault (Chapter 8 integration)

### Security Gates
- No critical vulnerabilities in production images
- All images signed with valid certificates
- SBOM successfully generated and stored
- Provenance attestation complete

## Pipeline Integration

### Observability Integration (Chapter 7)
- All pipeline events sent to OpenTelemetry
- Deployment success/failure metrics tracked
- Build performance metrics for optimization
- Integration with existing burn-rate alerting

### Secrets Management (Chapter 8)
- Pipeline service accounts managed in Vault
- Signing keys rotated on 30-day schedule
- Attestation storage in Vault backend
- Break-glass procedures for emergency deployments

### Cost Controls (Chapter 12)
- Deployment blocked if tenant budgets exceeded
- Resource usage monitoring during canary
- Automatic scaling prevention during high-cost periods
- Integration with cost anomaly detection

## Rollback Procedures
- Automatic rollback triggers documented in cicd/canary_rollout.md
- Manual rollback available within 5 minutes
- Database migration rollback procedures defined
- Service dependency rollback coordination

## Cross-References
- Branch protection: cicd/policy.md
- Canary rules: cicd/canary_rollout.md
- Supply chain details: cicd/supply_chain.md
- Release checklist: release_readiness.md