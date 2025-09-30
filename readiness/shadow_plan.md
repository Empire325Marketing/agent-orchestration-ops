# Shadow Deployment Plan

## Shadow Traffic Percentage by Route

### Core API Routes
- **`/api/v1/chat/completions`**: 5% shadow traffic
- **`/api/v1/embeddings`**: 10% shadow traffic
- **`/api/v1/completions`**: 5% shadow traffic

### Tool Integration Routes
- **`/api/v1/tools/search`**: 15% shadow traffic (high validation value)
- **`/api/v1/tools/execute`**: 20% shadow traffic (critical safety validation)
- **`/api/v1/tools/upload`**: 10% shadow traffic
- **`/api/v1/tools/query`**: 10% shadow traffic

### Administrative Routes
- **`/api/v1/health`**: 50% shadow traffic (low risk, high validation)
- **`/api/v1/metrics`**: 25% shadow traffic
- **`/api/v1/status`**: 30% shadow traffic

### Tenant-Specific Routing
- **Enterprise tier**: 3% shadow (higher stakes, more conservative)
- **Standard tier**: 8% shadow (balanced approach)
- **Starter tier**: 12% shadow (acceptable risk for testing)

## Data Anonymization

### Request Anonymization
- **PII removal**: Automatic detection and redaction of SSN, credit cards, emails
- **User identifiers**: Replace actual user IDs with anonymized shadow IDs
- **Session tracking**: Separate shadow session management
- **IP address**: Hash IP addresses for privacy protection

### Response Handling
- **Output isolation**: Shadow responses never returned to users
- **Logging separation**: Shadow logs stored separately from production
- **Metric isolation**: Shadow metrics tagged distinctly
- **Error handling**: Shadow errors don't affect production flows

### Data Retention
- **Shadow data**: 7-day retention for analysis
- **Anonymized logs**: 30-day retention for debugging
- **Performance metrics**: 90-day retention for trending
- **Compliance**: No PII stored in shadow data

## Deployment Window

### Phase 1: Initial Shadow (24 hours)
- **Traffic percentage**: Start at 1% across all routes
- **Monitoring focus**: Basic functionality and crash detection
- **Gate evaluation**: Performance and safety gates only
- **Rollback criteria**: Any 5xx errors or crashes

### Phase 2: Expanded Shadow (24-48 hours)
- **Traffic percentage**: Increase to target percentages per route
- **Monitoring focus**: Full gate evaluation active
- **Quality validation**: Golden test execution
- **Cost tracking**: Resource usage and efficiency measurement

### Phase 3: Full Shadow (48-72 hours)
- **Traffic percentage**: Maximum configured percentages
- **Monitoring focus**: Statistical significance validation
- **Final validation**: All readiness gates must pass
- **Promotion decision**: Automatic progression to canary if gates pass

### Emergency Extension
- **Extended validation**: Up to 120 hours for complex changes
- **Manual triggers**: Operator can extend shadow period
- **Investigation time**: Allow time for anomaly analysis
- **Conservative approach**: Prefer longer validation over risk

## Opt-Out Mechanisms

### Tenant Opt-Out
- **Configuration**: Per-tenant shadow participation flags
- **API control**: Tenants can disable shadow via API
- **Granular control**: Route-specific opt-out available
- **Default behavior**: Opt-in by default with notification

### User Opt-Out
- **Request headers**: `X-Primarch-No-Shadow: true` header support
- **Session-level**: Persistent opt-out for user sessions
- **Privacy compliance**: GDPR-compliant opt-out mechanisms
- **Documentation**: Clear opt-out procedures published

### Automated Opt-Out Triggers
- **High-sensitivity data**: Automatic opt-out for detected sensitive content
- **Compliance flags**: GDPR/CCPA subject requests exclude from shadow
- **Cost thresholds**: Opt-out tenants approaching budget limits
- **Performance impact**: Opt-out if shadow causes latency increase

## Rollback Procedures

### Immediate Rollback Triggers
- **Safety failures**: Any PII leak or jailbreak success
- **Performance degradation**: >20% latency increase
- **Error rate spike**: >2× baseline error rate
- **Resource exhaustion**: Memory/CPU above 90%

### Gradual Rollback Process
1. **Traffic reduction**: Immediately reduce shadow traffic to 1%
2. **Impact assessment**: Evaluate production system stability
3. **Root cause analysis**: Identify failure cause
4. **Complete shutdown**: Stop all shadow traffic if needed

### Rollback Decision Matrix
```yaml
rollback_triggers:
  critical:
    - pii_leak: immediate
    - security_breach: immediate
    - data_corruption: immediate

  warning:
    - performance_degradation: gradual
    - cost_overrun: gradual
    - quality_regression: investigate
```

### Recovery Procedures
- **Issue resolution**: Fix identified problems
- **Validation testing**: Re-run golden tests
- **Gradual re-enabling**: Restart shadow at 1% traffic
- **Extended monitoring**: Longer validation period post-recovery

## Monitoring and Alerting

### Real-Time Monitoring
- **Performance metrics**: Latency, throughput, error rates
- **Resource usage**: CPU, memory, disk, network utilization
- **Quality indicators**: Golden test pass rates
- **Cost tracking**: Per-request cost analysis

### Alert Configuration
- **Critical alerts**: Immediate escalation for safety/security issues
- **Warning alerts**: Performance and quality degradation
- **Info alerts**: Normal shadow deployment progress
- **Escalation**: Chapter 11 incident response procedures

### Dashboard Integration
- **Chapter 7 observability**: Shadow metrics in existing dashboards
- **Dedicated views**: Shadow-specific monitoring dashboards
- **Comparison views**: Side-by-side production vs shadow metrics
- **Trend analysis**: Historical shadow deployment success rates

## Integration with CI/CD

### Pipeline Integration
- **Automated triggers**: Shadow deployment starts after successful build
- **Gate validation**: Continuous gate evaluation during shadow period
- **Promotion logic**: Automatic progression to canary on gate pass
- **Failure handling**: Automatic rollback and pipeline termination

### Deployment Coordination
- **Chapter 10 CI/CD**: Shadow phase precedes canary deployment
- **Release pipeline**: Integrated with existing release processes
- **Rollback integration**: Unified rollback procedures
- **Audit logging**: All shadow actions logged to DECISIONS.log

## Cross-References
- Gate definitions: readiness/gates.md
- Quality metrics: readiness/quality_metrics.yaml
- CI/CD integration: cicd/canary_rollout.md
- Observability: Chapter 7 monitoring framework
- Incident response: runbooks/incident.md