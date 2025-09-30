# Model Routing Readiness Gate

**Chapter 38 - Model Routing & Batching Optimization**

## Gate Overview

The Model Routing Readiness Gate ensures the LiteLLM router, vLLM inference engines, and OpenAI Batch API integration are fully operational before allowing production traffic. All criteria must be met within a 30-minute measurement window.

## Pass/Fail Criteria

### Router Health & Availability ✅
**PASS if ALL true:**
- Router availability ≥ 99.9% (max 18s downtime in 30min window)
- Health check endpoint `/health` responding < 60s staleness
- Redis connection pool healthy with < 5% connection failures
- Circuit breaker state: CLOSED or HALF_OPEN (not OPEN)

**Measurement**: Prometheus query over 30m window
```promql
(
  sum(rate(router_requests_total[30m])) - 
  sum(rate(router_errors_total[30m]))
) / sum(rate(router_requests_total[30m])) >= 0.999
```

### Routing Performance & Error Rates ✅
**PASS if ALL true:**
- Overall routing error rate ≤ 1.0%
- Fallback success rate ≥ 95% when triggered
- Router P95 latency ≤ 150ms (routing decision only)
- No single provider contributing >50% of errors

**Measurement**: 
```promql
# Error rate
sum(rate(router_errors_total[30m])) / sum(rate(router_requests_total[30m])) <= 0.01

# Fallback success rate
sum(rate(router_fallback_success_total[30m])) / sum(rate(router_fallback_total[30m])) >= 0.95

# P95 latency
histogram_quantile(0.95, sum(rate(router_latency_seconds_bucket[30m])) by (le)) <= 0.15
```

### vLLM Engine Performance ✅
**PASS if ALL true:**
- vLLM batch utilization P95 ≥ 65% across all GPU pools
- KV cache hit rate P95 ≥ 80% for prefix caching efficiency
- GPU memory utilization between 70-90% (not over/under utilized)
- Queue depth P95 ≤ 100 requests per GPU pool
- Local inference availability ≥ 99.5%

**Measurement**:
```promql
# Batch utilization
histogram_quantile(0.95, sum(rate(vllm_batch_utilization_bucket[30m])) by (le, gpu_pool)) >= 0.65

# KV cache hit rate
histogram_quantile(0.95, sum(rate(vllm_kv_cache_hit_rate_bucket[30m])) by (le)) >= 0.80

# GPU memory utilization
avg_over_time(vllm_gpu_memory_utilization[30m]) >= 0.70 and <= 0.90

# Queue depth
histogram_quantile(0.95, sum(rate(vllm_queue_depth_bucket[30m])) by (le, gpu_pool)) <= 100
```

### Provider Distribution & Load Balancing ✅
**PASS if ALL true:**
- No single provider handling >80% of traffic (unless declared maintenance)
- Provider weights within ±10% of configured values
- All configured providers responding to health checks
- Cost per 1k tokens within budget thresholds per route tier

**Measurement**:
```promql
# Provider distribution
max(
  sum(rate(router_requests_total[30m])) by (provider) / 
  sum(rate(router_requests_total[30m]))
) <= 0.80

# Weight deviation
abs(
  (sum(rate(router_requests_total[30m])) by (provider) / sum(rate(router_requests_total[30m]))) -
  on(provider) group_left() router_configured_weight
) / on(provider) group_left() router_configured_weight <= 0.10
```

### Cost Control & Attribution ✅  
**PASS if ALL true:**
- Cost per 1k tokens ≤ planned budget per route tier (see `/srv/primarch/cost/budgets.yaml`)
- Daily cost variance ≤ 25% from 7-day rolling average
- Cost attribution coverage ≥ 95% (all requests properly tagged)
- No cost anomaly alerts firing for >15 minutes

**Measurement**:
```promql
# Cost per 1k tokens by tier
(
  sum(rate(billing_cost_total[30m])) by (route_tier) / 
  sum(rate(billing_tokens_total[30m])) by (route_tier)
) * 1000 <= on(route_tier) group_left() cost_budget_per_1k_tokens

# Attribution coverage  
sum(rate(router_requests_attributed_total[30m])) / sum(rate(router_requests_total[30m])) >= 0.95
```

### Observability & Tracing ✅
**PASS if ALL true:**
- Trace coverage ≥ 95% with routing decision annotations
- All required metrics present and updating (no stale metrics >5min)
- Log ingestion rate healthy (no dropped log entries)
- Grafana dashboards displaying current data

**Measurement**:
```promql
# Trace coverage
sum(rate(traces_total{span_kind="router"}[30m])) / sum(rate(router_requests_total[30m])) >= 0.95

# Metrics freshness
(time() - max(timestamp(router_requests_total))) <= 300
```

### OpenAI Batch Processing ✅
**PASS if ALL true:**
- Batch queue processing normally (depth not growing >2 hours)
- Batch success rate ≥ 95% for completed batches
- Average batch completion time ≤ 25 hours (within SLA buffer)
- Export pipeline healthy with no failed uploads

**Measurement**:
```promql
# Queue depth trend
increase(batch_queue_depth[2h]) <= 0

# Batch success rate
sum(rate(batch_completed_success_total[24h])) / sum(rate(batch_completed_total[24h])) >= 0.95

# Completion time
avg_over_time(batch_completion_time_hours[24h]) <= 25
```

## Failure Response Actions

### FAIL → Immediate Actions
1. **Block deployment** of routing configuration changes
2. **Trigger alert** to on-call engineer with specific failure details
3. **Run appropriate runbook**:
   - Router issues: `/srv/primarch/runbooks/router-outage.md`
   - vLLM issues: Check GPU health, restart engines if needed
   - Batch issues: `/srv/primarch/runbooks/batch-failure.md`
   - Cost issues: Activate emergency cost controls

### Re-testing Protocol
1. **Address root cause** based on failure category
2. **Wait minimum 10 minutes** for metrics to stabilize
3. **Re-run all gate criteria** (no partial passes)
4. **Document failure and resolution** in `/srv/primarch/DECISIONS.log`

## Emergency Overrides

### Override Conditions
Gate failures may be overridden ONLY when:
- P0 incident requiring immediate routing changes for service restoration
- Pre-approved maintenance window with documented risk acceptance
- Critical security patch deployment with ops team approval

### Override Process
1. **Ops Lead approval** required in incident channel
2. **Document override reason** with ticket reference
3. **Implement additional monitoring** during override period
4. **Mandatory gate re-test** within 4 hours of override

## Automation Integration

### CI/CD Pipeline
```yaml
# .github/workflows/routing-deploy.yml
- name: Run Routing Readiness Gate
  run: |
    ./scripts/routing-gate-check.sh --timeout=30m
    if [ $? -ne 0 ]; then
      echo "❌ Routing readiness gate FAILED - blocking deployment"
      exit 1
    fi
    echo "✅ Routing readiness gate PASSED - proceeding with deployment"
```

### Monitoring Integration
- **AlertManager** rules automatically trigger gate re-evaluation on failures
- **Grafana** dashboard shows real-time gate status with red/green indicators  
- **Slack** notifications sent to `#primarch-ops` on gate status changes

## Metrics Dashboard

Access the routing readiness dashboard at:
`https://grafana.primarch.internal/d/routing-readiness/model-routing-readiness-gate`

Key panels:
- Gate Status Overview (pass/fail indicators)
- Router Health Metrics
- vLLM Performance Metrics  
- Provider Distribution
- Cost and Attribution Tracking
- Batch Processing Status

---

**Gate Status**: 🔄 *Evaluate all criteria before marking PASS/FAIL*

**Last Updated**: 2025-09-30 | **Next Review**: 2025-10-30

**Owner**: Platform Engineering | **On-Call**: #primarch-ops
