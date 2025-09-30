# Chapter 12 — Cost Guardrails

## Goals
- Prevent budget overruns through automated enforcement
- Maintain service availability with graceful degradation
- Provide predictable cost control for multi-tenant platform
- Enable self-service budget management with safety nets

## Default Tenant Budget
- **Daily cap**: $10/day baseline (configurable per tenant tier)
- **Burst allowance**: 50 req/hr above normal baseline
- **Grace period**: 24-hour soft warning before enforcement
- **Emergency override**: Operator-controlled temporary lift

## Enforcement Layers

### Layer 1: Gateway Limits (Kong)
- Pre-flight cost estimation based on request size
- Rate limiting tied to budget consumption rate
- Immediate rejection when daily cap exceeded
- Transparent cost headers in responses

### Layer 2: Orchestrator Downgrades
- Context window reduction for LLM requests
- Tool availability restrictions for expensive operations
- Queue prioritization based on budget status
- Batch processing for non-urgent requests

### Layer 3: Model/Provider Fallbacks
- Automatic downgrade ladder: GPT-4 → GPT-3.5 → Local Llama
- Vector search complexity reduction
- Cache-first strategies when approaching limits
- Simplified responses for cost-sensitive operations

## Observability Integration
- Real-time spend tracking per tenant
- Cost attribution per request/operation type
- Budget burn rate analysis and predictions
- Alert integration with existing Chapter 7 framework
- Cost anomaly detection and auto-investigation

## Cross-References
- Budgets configuration: cost/budgets.yaml
- Policy enforcement: cost/cost_policy.md
- Monitoring rules: observability/cost_rules.prom
- Response procedures: runbooks/cost-guardrails.md
- Proxy policies: Chapter 6 network restrictions