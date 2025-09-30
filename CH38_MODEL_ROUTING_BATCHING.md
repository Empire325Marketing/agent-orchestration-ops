# Chapter 38 — Model Routing & Batching Optimization

## Executive Summary

Primarch implements intelligent model routing and request batching to optimize cost, latency, and reliability across heterogeneous LLM providers. This chapter establishes the architecture for LiteLLM-based routing with vLLM local inference and OpenAI Batch API integration, achieving 40-60% cost reduction while maintaining sub-2s p95 latency for interactive workloads.

## Decision Summary

**Primary Decision**: Adopt LiteLLM Router as the unified routing layer with usage-based weighting, vLLM for local GPU inference, and OpenAI Batch API for cost-optimized async processing.

**Key Components**:
- **Router**: LiteLLM with Redis state, circuit breaker, and weighted fallbacks
- **Local Inference**: vLLM on GPU pools (2×RTX5090 + 1×RTX3090) with continuous batching
- **Batch Processing**: OpenAI Batch API for non-interactive workloads (24h SLA)
- **Strategy**: Usage-based routing with cost-aware fallbacks

## Scope & Architecture

### In Scope
1. **Multi-Provider Routing**: OpenAI, Azure OpenAI, Anthropic, local vLLM
2. **Intelligent Batching**: Request coalescing, continuous batching, queue optimization  
3. **Cost Optimization**: Usage-based weights, batch profiles, provider arbitrage
4. **Resilience**: Circuit breakers, fallbacks, graceful degradation
5. **Observability**: Routing decisions, cost attribution, performance metrics

### Non-Goals
- Fine-tuning or model serving beyond vLLM integration
- Custom tokenizers or prompt engineering (handled by agent layer)
- Multi-tenant isolation at routing level (delegated to auth/policy)

### GPU Pool Architecture
```
Pool A (RTX5090): Primary inference, 32K context
Pool B (RTX5090): Overflow/failover, 32K context  
Pool C (RTX3090): Spillover, 16K context limit
```

### Route Decision Flow
```
Request → LiteLLM Router → [Weight Check] → Provider Selection → Fallback Chain
                ↓
         Circuit Breaker → Usage Metrics → Cost Optimization → Response
```

## Integration Points

This chapter integrates with:

- **Ch.10 (CI)**: Canary routing, config validation, rollback automation
- **Ch.12 (Cost)**: Token metering, provider cost attribution, budget controls
- **Ch.13 (Readiness)**: Routing health gates, SLA compliance validation  
- **Ch.15 (DR)**: Router failover, state recovery, RTO/RPO compliance
- **Ch.21 (Support)**: Error attribution, provider SLA tracking, escalation
- **Ch.24 (Billing)**: Usage aggregation, cost allocation, batch export billing

## Configuration Strategy

### Router Weights (Production)
- **OpenAI GPT-4**: 60% (primary, highest quality)
- **Azure OpenAI**: 25% (cost optimization, compliance)  
- **Anthropic Claude**: 15% (fallback, context length)
- **vLLM Local**: Overflow + cost-sensitive routes

### Batching Profiles
- **Interactive**: Sub-2s target, continuous batching, immediate routing
- **Analytical**: 24h SLA, OpenAI Batch API, cost-optimized
- **Document Processing**: Mixed mode based on urgency flags

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Router P95 Latency | <100ms | End-to-end routing decision |
| Fallback Success Rate | >95% | Successful backup provider usage |
| Cost Reduction | 40-60% | vs. single-provider baseline |
| Batch Utilization | >65% | vLLM GPU utilization P95 |
| KV Cache Hit Rate | >80% | Prefix caching efficiency |
| Circuit Breaker Accuracy | <5% false positive | Error detection precision |

## Security & Compliance

- **PII Handling**: Automatic redaction in batch exports
- **Provider Isolation**: No cross-contamination of API keys
- **Audit Trail**: All routing decisions logged with tenant attribution
- **Rate Limiting**: Per-tenant and per-provider enforcement
- **Idempotency**: SHA256-based deduplication for batch operations

## Operational Model

### Deployment
- Blue/green deployment with canary routing weights
- Configuration as code with Vault secret injection
- Automated rollback on SLO burn rate >2×

### Monitoring
- Real-time routing metrics and cost attribution
- Provider health monitoring with automatic circuit breaker
- Batch queue depth and processing SLA tracking

### Support
- Provider-specific error routing to appropriate support channels
- Cost anomaly detection and automatic budget alerts
- Capacity planning based on usage growth projections

## Migration Strategy

### Phase 1: Router Deployment (Week 1)
- Deploy LiteLLM router with OpenAI + Azure failover
- 10% canary traffic, validate latency and error rates

### Phase 2: vLLM Integration (Week 2-3)  
- Bring up local GPU pools with Llama-3.1-8B
- Route cost-sensitive workloads to local inference
- Tune batching parameters for optimal throughput

### Phase 3: Batch Optimization (Week 4)
- Deploy OpenAI Batch profiles for analytical workloads
- Implement queue-based async processing
- Cost attribution and billing integration

### Phase 4: Full Production (Week 5+)
- 100% traffic through router with usage-based weights
- All observability and alerting operational
- Runbook validation and team training complete

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Router SPOF | High | Redis clustering, multi-AZ deployment |
| GPU Pool Failure | Medium | Automatic fallback to cloud providers |
| Cost Overrun | Medium | Budget alerts, circuit breakers, quotas |
| Latency Regression | High | Canary deployment, automatic rollback |
| Provider API Changes | Medium | Circuit breaker, fallback chains |

## Success Criteria

**Technical**:
- ✅ All routing gates pass (availability >99.9%, errors <1%)
- ✅ Cost reduction targets achieved (40-60% vs baseline)
- ✅ Latency within SLA (P95 <2s interactive, 24h batch)

**Operational**:
- ✅ Zero-downtime deployment and configuration updates
- ✅ Mean time to resolution <30min for routing issues
- ✅ Complete observability and cost attribution

**Business**:
- ✅ Infrastructure cost reduction of $XX,XXX/month
- ✅ Improved response time user satisfaction scores
- ✅ Reduced vendor lock-in and negotiation leverage

---

*Chapter 38 establishes the foundation for intelligent, cost-optimized model routing while maintaining Primarch's reliability and performance standards. The architecture balances cost efficiency with operational simplicity, providing a scalable platform for multi-provider LLM orchestration.*
