# Vulnerability Readiness Gate

## Gate criteria
- **Zero critical vulnerabilities** in production deployment
- **High vulnerabilities**: Must have mitigation plan or exception
- **SBOM coverage**: ≥95% of deployed components
- **Scan recency**: Vulnerability scan <24h old
- **Provenance**: All artifacts signed and attested

## Evaluation process
1. Pre-deployment: Scan target deployment artifacts
2. Compare against vulnerability database (updated hourly)
3. Check for active exceptions and their expiry dates
4. Validate compensating controls are in place
5. Generate readiness report with recommendations

## Fail actions
- **Block deployment** on gate failure
- **Alert security team** on critical findings
- **Create tracking ticket** for remediation
- **Log decision** in immutable audit trail (Ch.31)

## Override conditions
- Emergency security patch deployment
- Pre-approved maintenance window
- Business-critical deployment with CISO sign-off
