# Cost Policy

## $/Request Calculator

### Base Cost Components
- **LLM inference**: $0.002 per 1K input tokens, $0.006 per 1K output tokens
- **Vector operations**: $0.001 per embedding request, $0.0001 per similarity search
- **External API calls**: Variable per provider (see tool registry Chapter 5)
- **Storage operations**: $0.00001 per KB stored/retrieved
- **Bandwidth**: $0.001 per MB egress

### Cost Estimation Algorithm
```
request_cost = (
    (input_tokens / 1000 * input_rate) +
    (estimated_output_tokens / 1000 * output_rate) +
    (api_calls * api_rate) +
    (storage_kb * storage_rate) +
    (bandwidth_mb * bandwidth_rate)
)
```

## Throttle Algorithm

### Token Limits
- **Input context reduction**: 32K → 16K → 8K → 4K based on budget status
- **Output length caps**: Progressive reduction at 75%, 90%, 95% budget
- **Batch size limits**: Reduce concurrent requests when approaching limits

### QPS (Queries Per Second) Caps
- **50% budget**: Normal rate (no throttling)
- **75% budget**: 80% of normal rate
- **90% budget**: 50% of normal rate
- **95% budget**: 25% of normal rate
- **100% budget**: Emergency requests only (operator override)

### Throttle Implementation
```
if budget_used_percent >= 90:
    apply_hard_throttle()  # 50% rate reduction
elif budget_used_percent >= 75:
    apply_soft_throttle()  # 20% rate reduction

throttle_factor = max(0.25, (100 - budget_used_percent) / 100)
actual_rate = base_rate * throttle_factor
```

## Downgrade Triggers

### Quota-Based Triggers
- **>80% daily budget**: Enable model downgrade ladder
- **>90% daily budget**: Disable expensive tools (web search, code execution)
- **>95% daily budget**: Context window reduction to minimum viable
- **>100% daily budget**: Service suspension with read-only access

### Spend vs Plan Triggers
- **2x planned daily rate**: Immediate soft throttle activation
- **5x planned daily rate**: Hard throttle + operator notification
- **10x planned daily rate**: Emergency circuit breaker activation

## Kill-Switch Semantics

### Temporary Hard Block
- **Trigger**: 100% budget exceeded OR 10x spend rate anomaly
- **Duration**: 24 hours default (configurable per tenant)
- **Scope**: New requests blocked, existing sessions preserved for 1 hour
- **Exceptions**: Emergency operator override, billing updates, read operations

### Operator Override
- **Activation**: Dual approval required (reference Chapter 8 break-glass)
- **Duration**: Time-limited (4 hours max) with automatic expiry
- **Logging**: All override actions logged to DECISIONS.log
- **Notification**: Real-time alerts to operations team

### Graceful Recovery
1. Payment processing or budget increase
2. 15-minute staged service restoration
3. Monitor for immediate re-triggering
4. Update tenant communication with new limits

## Cross-References
- Budget configuration: cost/budgets.yaml
- Monitoring rules: observability/cost_rules.prom
- Response procedures: runbooks/cost-guardrails.md
- Tool registry costs: Chapter 5 API management
- Break-glass procedures: Chapter 8 secrets management