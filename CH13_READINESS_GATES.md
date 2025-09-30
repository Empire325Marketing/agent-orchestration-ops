# Chapter 13 — Readiness Gates

## Decision Summary
- **Three-stage promotion**: Shadow → Canary → Full rollout with enforced gates
- **Multi-dimensional validation**: Performance, quality, safety, cost, and compliance
- **Automated blocking**: No manual override for gate failures (emergency break-glass only)
- **Continuous monitoring**: Real-time validation during shadow and canary phases
- **Quality-first approach**: Automated win-rate and safety validation before human exposure

## Scope

### Performance Gates
- API response time SLOs maintained under load
- LLM inference latency within acceptable bounds
- Error rate regression detection and blocking
- Resource utilization and capacity validation

### Quality Gates
- Automated golden test suite validation
- Win-rate maintenance against baseline
- Regression detection across model outputs
- Factual consistency and accuracy verification

### Safety Gates
- Zero tolerance for PII leakage in outputs
- Jailbreak attempt detection and blocking
- Content toxicity monitoring and filtering
- Prompt injection vulnerability scanning

### Cost Gates
- Per-request cost projections within budget
- Tenant headroom validation before promotion
- Spend anomaly detection and prevention
- Resource efficiency verification

### Compliance Gates
- Data retention and deletion policy enforcement
- Audit trail completeness verification
- DPIA flag monitoring and blocking
- Regulatory requirement validation

## Non-Goals
- Manual quality assessment (fully automated validation)
- A/B testing frameworks (simple shadow/canary sufficient)
- Advanced ML model evaluation (basic metrics adequate for MVP)
- Multi-region promotion coordination (single region focus)

## Integration Points

### Chapter 6 — Sandbox & Proxy Integration
- **Network isolation validation**: Ensure sandbox policies enforced in new deployments
- **Egress monitoring**: Validate allowlist compliance during shadow testing
- **Security posture**: Confirm isolation boundaries maintained

### Chapter 7 — Observability Integration
- **SLO monitoring**: Real-time burn rate calculation during promotions
- **Trace coverage gates**: Minimum 95% trace coverage required
- **Dashboard validation**: Golden signal health before promotion
- **Alert integration**: Gate failures trigger observability alerts

### Chapter 8 — Secrets & IAM Integration
- **Credential validation**: Ensure all required secrets available and rotated
- **Access control**: Validate IAM policies for new deployment versions
- **Break-glass procedures**: Emergency override with dual approval

### Chapter 10 — CI/CD Integration
- **Pipeline gates**: Readiness gates embedded in release pipeline
- **Rollback triggers**: Failed gates trigger automatic rollback
- **SBOM validation**: Supply chain security gates integrated

### Chapter 12 — Cost Integration
- **Budget validation**: Cost gates prevent budget overrun
- **Tenant limits**: Per-tenant spending validation
- **Anomaly detection**: Unusual cost patterns block promotion

## Architecture Overview
Shadow deployment validates all dimensions before exposing to real users. Canary phase provides controlled real-world validation. Gates must pass at each stage before progression.

## Cross-References
- Gate definitions: readiness/gates.md
- Test specifications: readiness/golden_tests.md
- Shadow strategy: readiness/shadow_plan.md
- Quality metrics: readiness/quality_metrics.yaml
- Release readiness: release_readiness.md