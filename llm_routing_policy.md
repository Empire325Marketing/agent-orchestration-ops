# LLM Routing Policy (MVP)

## GPU Pool Definitions

### Pool A (Primary) - RTX 5090
- **GPU Model**: RTX 5090
- **Weight**: 70% (primary traffic routing)
- **Max Batch Size**: 32 requests
- **Context Cap**: 32K tokens
- **Priority**: Highest performance tier

### Pool B (Secondary) - RTX 5090
- **GPU Model**: RTX 5090
- **Weight**: 20% (load balancing)
- **Max Batch Size**: 32 requests
- **Context Cap**: 32K tokens
- **Priority**: High performance tier

### Pool C (Overflow) - RTX 3090
- **GPU Model**: RTX 3090
- **Weight**: 10% (overflow and cost optimization)
- **Max Batch Size**: 16 requests
- **Context Cap**: 16K tokens
- **Priority**: Cost-optimized tier

## Failover Routing Order

### Primary Routing (Weighted)
- **Pool A**: 70% of traffic under normal conditions
- **Pool B**: 20% of traffic under normal conditions
- **Pool C**: 10% of traffic under normal conditions

### Failover Sequence
1. **Pool A → Pool B**: If Pool A unavailable or overloaded
2. **Pool B → Pool C**: If Pool B unavailable or overloaded
3. **Pool C → Cloud**: If all local pools unavailable (region/PII constraints apply)

### Downgrade Ladder for Overflow
- **Context >16K**: Route to Pool A or B only
- **Context ≤16K**: Can route to Pool C for cost optimization
- **High priority requests**: Always prefer Pool A/B
- **Batch requests**: Route to Pool C when available

## Local-first Strategy
Default routing uses on-prem llama-3.1-8b-instruct across GPU pools for all requests.

## Region & PII Constraints
HR PII data in CN and EU must remain in-region. Cloud routes are blocked unless lawful basis and transfer mechanism are recorded.

## Health & Quota Signals
Failover triggers activate on runtime unavailability, repeated 5xx errors, or quota burn exceeding 80%.

## Observability
Each routing decision is logged with reason, outcome, and pool assignment, without sensitive content.