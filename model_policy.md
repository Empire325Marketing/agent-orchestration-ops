# Model Policy — On-prem (MVP)

## Baseline Model
The baseline model ID is llama-3.1-8b-instruct with AWQ quantization for MVP and FP8 alternative noted. Context target tokens are set to 32000 with maximum prompt tokens of 8000 and maximum output tokens of 1500. Temperature range spans 0.0–0.8 with default of 0.2–0.4. Stop sequences are documented per route.

## Per-Pool Resource Limits

### Pool A (RTX 5090 Primary)
- **Tokens/sec**: 2000 tokens/sec sustained
- **Concurrent Inflight**: 32 requests maximum
- **Memory Threshold**: 85% VRAM utilization trigger
- **Batch Processing**: Up to 32 concurrent requests

### Pool B (RTX 5090 Secondary)
- **Tokens/sec**: 2000 tokens/sec sustained
- **Concurrent Inflight**: 32 requests maximum
- **Memory Threshold**: 85% VRAM utilization trigger
- **Batch Processing**: Up to 32 concurrent requests

### Pool C (RTX 3090 Overflow)
- **Tokens/sec**: 1200 tokens/sec sustained
- **Concurrent Inflight**: 16 requests maximum
- **Memory Threshold**: 80% VRAM utilization trigger
- **Batch Processing**: Up to 16 concurrent requests

## Brownout Eviction Rules

### Priority-Based Eviction
1. **Low priority requests** evicted first (background tasks, batch jobs)
2. **Standard requests** evicted if >90% pool utilization
3. **High priority requests** protected unless critical system failure

### Pool-Specific Eviction Thresholds
- **Pool A**: Eviction at 95% utilization (highest tolerance)
- **Pool B**: Eviction at 90% utilization (balanced approach)
- **Pool C**: Eviction at 85% utilization (aggressive eviction for stability)

### Eviction Actions
- **Graceful termination**: Allow in-flight requests to complete when possible
- **Request queuing**: Queue new requests during high utilization
- **Pool migration**: Move requests to less utilized pools
- **Rate limiting**: Reduce incoming request rate to manageable levels

## Guardrails
External network access is disallowed except for sanctioned search proxy when explicitly enabled. PII redaction in logs is enabled. Tool use is allowed but policy-gated. Prompt caching is disabled while embedding caching is enabled for the RAG layer.

## Telemetry
Trace emission is enabled with 100% sampling for errors, 50% for slow requests, and 10% default sampling. Metrics include tokens_in, tokens_out, duration_ms, rate_limited count, failures, and per-pool utilization.

## Change Control
Version gate is required with rollback on SLO breach enabled. Promotion criteria require passing functional, performance, and compliance checks.