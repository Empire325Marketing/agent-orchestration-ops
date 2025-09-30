# Model Router Outage Response Runbook

**Chapter 38 - Model Routing & Batching Optimization**

## Overview

This runbook provides step-by-step procedures for diagnosing and resolving model router outages, including LiteLLM routing failures, provider instability, and performance degradation.

## Alert Classification

### P0 - Critical Outage (Complete Router Failure)
- Router completely unresponsive
- Error rate >50% for >5 minutes
- All providers failing simultaneously

### P1 - Partial Outage (Degraded Performance)
- Error rate 5-50% for >10 minutes
- Single provider failures with inadequate fallback
- Circuit breaker cascade failures

### P2 - Performance Degradation
- Error rate 1-5% for >15 minutes
- Elevated latency but functional routing
- Capacity planning concerns

## Incident Response Process

### 1. Immediate Assessment (0-5 minutes)

#### Check Router Status
```bash
# Check router health endpoint
curl -f http://litellm-router:8080/health || echo "Router health check FAILED"

# Check Prometheus metrics endpoint
curl -f http://litellm-router:8080/metrics | grep -E "(router_requests_total|router_errors_total)" || echo "Metrics endpoint FAILED"

# Check process status
kubectl get pods -l app=litellm-router -n primarch
kubectl describe pods -l app=litellm-router -n primarch
```

#### Quick Metrics Review
```bash
# Check current error rate (last 5 minutes)
prometheus-cli query 'sum(rate(router_errors_total[5m])) / sum(rate(router_requests_total[5m]))'

# Check provider status
prometheus-cli query 'up{job="litellm-router"}' 
prometheus-cli query 'router_circuit_breaker_state'
```

#### Verify External Dependencies
```bash
# Redis connectivity
redis-cli -h router-redis ping

# Provider API health checks
curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
curl -H "x-api-key: $ANTHROPIC_API_KEY" https://api.anthropic.com/v1/messages
```

### 2. Immediate Mitigation (5-10 minutes)

#### Router Recovery Actions
```bash
# Restart router if completely unresponsive
kubectl rollout restart deployment/litellm-router -n primarch

# Clear Redis state if corrupted
redis-cli -h router-redis FLUSHDB

# Force circuit breaker reset
curl -X POST http://litellm-router:8080/admin/circuit-breaker/reset
```

#### Emergency Traffic Routing
```bash
# Switch to weighted routing with stable providers only
kubectl patch configmap litellm-config -n primarch --patch '
data:
  litellm_router.yaml: |
    routing:
      strategy: weighted
    weights:
      gpt-4-turbo:
        openai-gpt4-turbo: 70
        azure-gpt4-turbo: 30
        anthropic-claude-3-opus: 0  # Disable if problematic
'

# Apply emergency configuration
kubectl rollout restart deployment/litellm-router -n primarch
```

#### Provider-Specific Actions

**If OpenAI is failing:**
```bash
# Increase Azure and Anthropic weights
kubectl patch configmap litellm-config -n primarch --patch '
data:
  weights:
    gpt-4-turbo:
      openai-gpt4-turbo: 0
      azure-gpt4-turbo: 60
      anthropic-claude-3-opus: 40
'
```

**If vLLM local inference is failing:**
```bash
# Check GPU status
nvidia-smi
kubectl logs -l app=vllm-engine -n primarch --tail=100

# Restart vLLM if needed
kubectl rollout restart deployment/vllm-engine -n primarch

# Temporarily route local traffic to cloud providers
kubectl patch configmap litellm-config -n primarch --patch '
data:
  weights:
    llama-3.1-8b-instruct:
      vllm-local-llama-3-1-8b: 0
      openai-gpt4o-mini: 100
'
```

### 3. Root Cause Analysis (10-30 minutes)

#### Log Analysis
```bash
# Router application logs
kubectl logs -l app=litellm-router -n primarch --since=30m | grep -E "(ERROR|CRITICAL|circuit_breaker)"

# System resource usage
kubectl top pods -l app=litellm-router -n primarch
kubectl describe nodes

# Database connections and performance
redis-cli -h router-redis INFO stats
redis-cli -h router-redis INFO clients
```

#### Performance Metrics Deep Dive
```bash
# Provider-specific error patterns
prometheus-cli query 'sum(rate(router_errors_total[30m])) by (provider, reason)'

# Latency breakdown by component
prometheus-cli query 'histogram_quantile(0.95, sum(rate(router_latency_seconds_bucket[30m])) by (le, component))'

# Circuit breaker activation timeline
prometheus-cli query 'changes(router_circuit_breaker_state[30m])'
```

#### External Provider Issues
```bash
# Check provider status pages
curl -s https://status.openai.com/api/v2/status.json | jq .
curl -s https://status.anthropic.com/api/v2/status.json | jq .

# Test individual provider latency
time curl -X POST https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{"model": "gpt-4-turbo-preview", "messages": [{"role": "user", "content": "test"}], "max_tokens": 5}'
```

### 4. Stabilization and Recovery (30-60 minutes)

#### Gradual Weight Restoration
```bash
# Slowly restore weights to problematic providers
# Start with 10% traffic
kubectl patch configmap litellm-config -n primarch --patch '
data:
  weights:
    gpt-4-turbo:
      openai-gpt4-turbo: 10
      azure-gpt4-turbo: 50
      anthropic-claude-3-opus: 40
'

# Monitor for 15 minutes, then increase if stable
# Continue until full restoration or identify permanent issues
```

#### Canary Validation
```bash
# Run canary test with small traffic percentage
./scripts/canary-test.sh --provider=openai --traffic-pct=10 --duration=15m

# Check metrics during canary
prometheus-cli query 'sum(rate(router_errors_total{provider="openai"}[5m])) / sum(rate(router_requests_total{provider="openai"}[5m]))'
```

#### Configuration Optimization
```bash
# Adjust circuit breaker sensitivity if needed
kubectl patch configmap litellm-config -n primarch --patch '
data:
  routing:
    circuit_breaker_error_rate: 0.10  # More lenient during recovery
    cooldown_s: 120                   # Longer cooldown
'

# Update timeout settings for problematic providers
kubectl patch configmap litellm-config -n primarch --patch '
data:
  routing:
    timeout_s: 60                     # Increased timeout
'
```

### 5. Documentation and Follow-up (Post-incident)

#### Incident Documentation
```bash
# Append incident details to decisions log
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | OPERATOR=$USER | CHAPTER=38 | ACTION=resolve_outage | INCIDENT=$INCIDENT_ID | CAUSE=$ROOT_CAUSE | MTTR=${MTTR_MINUTES}m | IMPACT=$IMPACT_DESCRIPTION" >> /srv/primarch/DECISIONS.log

# Create incident report
cat > /srv/primarch/reports/router_incident_$(date +%Y%m%d_%H%M).md << EOF
# Router Incident Report - $(date)

## Summary
- **Incident ID**: $INCIDENT_ID
- **Start Time**: $INCIDENT_START
- **End Time**: $INCIDENT_END
- **MTTR**: $MTTR_MINUTES minutes
- **Impact**: $IMPACT_DESCRIPTION

## Root Cause
$ROOT_CAUSE_ANALYSIS

## Actions Taken
$ACTIONS_TAKEN

## Prevention Measures
$PREVENTION_MEASURES
EOF
```

#### Post-Incident Actions
1. **Schedule post-mortem** within 48 hours
2. **Update monitoring thresholds** based on incident learnings
3. **Review and update runbook** with new procedures discovered
4. **Consider architectural improvements** to prevent recurrence

## Common Scenarios and Solutions

### Scenario 1: Redis Connection Pool Exhaustion
**Symptoms**: Connection timeout errors, slow routing decisions
**Solution**: 
```bash
# Increase Redis connection pool size
redis-cli -h router-redis CONFIG SET maxclients 10000
# Update router configuration with larger pool
```

### Scenario 2: Provider API Key Rotation Issues
**Symptoms**: 401/403 errors from specific providers
**Solution**:
```bash
# Update API keys in Kubernetes secrets
kubectl patch secret provider-api-keys -n primarch --patch='{"data":{"OPENAI_API_KEY":"'$(echo -n $NEW_OPENAI_KEY | base64)'"}}'
# Restart router to pick up new secrets
kubectl rollout restart deployment/litellm-router -n primarch
```

### Scenario 3: Memory Leak in Router Process
**Symptoms**: Gradually increasing memory usage, eventual OOM kills
**Solution**:
```bash
# Immediate: Restart router
kubectl rollout restart deployment/litellm-router -n primarch
# Long-term: Implement memory monitoring alerts and periodic restarts
```

### Scenario 4: vLLM GPU Out of Memory
**Symptoms**: Local inference failures, CUDA out of memory errors
**Solution**:
```bash
# Reduce batch size and model parameters
kubectl patch configmap vllm-config -n primarch --patch '
data:
  models[0].engine.max_num_seqs: "1024"
  models[0].engine.gpu_memory_utilization: "0.75"
'
```

## Emergency Contacts

### Escalation Path
1. **On-Call Engineer** - Primary response (0-15 min)
2. **Platform Engineering Lead** - Technical escalation (15+ min)
3. **VP Engineering** - Business impact escalation (30+ min)
4. **Provider Support** - External provider issues

### External Support
- **OpenAI Support**: support@openai.com (Enterprise tier)
- **Anthropic Support**: support@anthropic.com
- **Azure Support**: Azure portal support case
- **LiteLLM Community**: GitHub issues/Discord

## Prevention and Monitoring

### Proactive Monitoring
- Circuit breaker state monitoring
- Provider response time SLA tracking
- Capacity utilization trending
- Cost anomaly detection

### Regular Maintenance
- Weekly configuration backup
- Monthly provider performance review
- Quarterly disaster recovery testing
- Semi-annual runbook validation exercises

---

**Last Updated**: 2025-09-30 | **Next Review**: 2025-10-30
**Owner**: Platform Engineering | **On-Call**: #primarch-ops
