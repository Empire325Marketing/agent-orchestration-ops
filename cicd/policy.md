# CI/CD Policy

## Branch Protection Rules

### Main Branch Protection
- **Direct pushes**: Disabled (no exceptions)
- **Force pushes**: Disabled (no exceptions)
- **Deletion**: Disabled
- **Required status checks**: All CI pipeline stages must pass
- **Up-to-date branches**: Required before merge
- **Signed commits**: Required for all commits

### Protected Branch Rules
```yaml
main:
  protect: true
  required_status_checks:
    - "ci/verify-pipeline"
    - "ci/security-scan"
    - "ci/test-coverage"
  required_reviews:
    count: 2
    dismiss_stale: true
    require_code_owner: true
  restrictions:
    push: []
    merge: ["maintainers", "security-team"]
```

## Required Checks and Reviews

### Automated Checks (Required)
- **Verify Pipeline**: Must pass all stages
- **Security Scan**: No critical vulnerabilities
- **Test Coverage**: Minimum 80% coverage maintained
- **Lint Status**: All linting rules pass
- **Build Success**: Artifacts build successfully

### Manual Reviews (Required)
- **Minimum reviewers**: 2 approved reviews required
- **Code owner review**: Required for core system changes
- **Security review**: Required for authentication, cryptography, or data handling changes
- **Dismiss stale reviews**: Enabled when new commits pushed

### Review Exemptions
- **Documentation-only changes**: 1 reviewer sufficient
- **Emergency hotfixes**: Reduced to 1 reviewer with post-deployment review
- **Automated dependency updates**: Auto-merge if security scans pass

## Commit Requirements

### Signed Commits
- **GPG signing**: Required for all commits to main
- **Verification**: Commits must be verified before merge
- **Key management**: Developer keys registered and validated
- **Rotation**: Annual key rotation recommended

### Commit Message Standards
```
type(scope): brief description

Longer description if needed

Fixes: #issue-number
Signed-off-by: Developer Name <email@example.com>
```

### Commit Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting
- `refactor`: Code restructuring
- `test`: Test additions/modifications
- `chore`: Maintenance tasks

## Environment Approvals

### Staging Environment
- **Auto-deployment**: Enabled after main branch merge
- **Manual approval**: Not required
- **Testing validation**: Automated smoke tests must pass

### Production Environment
- **Manual approval**: Required from ops team
- **Approval window**: 4-hour business hours window (9 AM - 1 PM UTC)
- **Emergency override**: Available with dual approval (Chapter 8 break-glass)
- **Deployment window**: Tuesday-Thursday only (excluding holidays)

### Approval Matrix
```yaml
environments:
  staging:
    auto_deploy: true
    approvers: []
  production:
    auto_deploy: false
    required_approvers: 2
    approver_teams: ["ops-team", "security-team"]
    emergency_override: true
```

## Artifact and Provenance Retention

### Artifact Storage
- **Container images**: 90 days in production registry
- **Build artifacts**: 30 days in artifact store
- **Test results**: 60 days for compliance
- **Security scan results**: 1 year retention

### Provenance Retention
- **Build provenance**: 90 days minimum (compliance requirement)
- **Signing attestations**: 1 year retention
- **SBOM records**: 90 days active, 1 year archived
- **Deployment logs**: 6 months (DECISIONS.log integration)

### Storage Locations
- **Vault backend**: Signing keys and attestations (Chapter 8)
- **Container registry**: Images and signatures
- **Artifact store**: Build outputs and test results
- **Compliance archive**: Long-term retention for audits

## Policy Enforcement

### Automated Enforcement
- Branch protection rules enforced by Git provider
- Pipeline checks cannot be bypassed
- Signing verification automatic
- Approval requirements system-enforced

### Manual Override Procedures
- **Emergency deployments**: Chapter 8 break-glass procedures
- **Policy exceptions**: Security team approval required
- **Temporary relaxation**: Time-limited with automatic restoration
- **Audit trail**: All overrides logged to DECISIONS.log

## Integration Points
- **Vault secrets**: Pipeline authentication and signing keys
- **Observability**: Policy violation monitoring and alerting
- **Compliance**: Audit trail and retention requirements
- **Cost controls**: Deployment blocking for budget overruns

## Cross-References
- Emergency procedures: Chapter 8 break-glass procedures
- Pipeline definitions: cicd/pipelines.md
- Canary deployment: cicd/canary_rollout.md
- Supply chain security: cicd/supply_chain.md