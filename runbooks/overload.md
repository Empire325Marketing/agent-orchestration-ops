# Runbook — System Overload

## Admission Control
1) Monitor request queue depth and processing latency
2) Reject new requests when queue exceeds threshold (1000 pending)
3) Return HTTP 503 with Retry-After header
4) Prioritize existing authenticated sessions over new requests
5) Log admission control activation to DECISIONS.log

## Retry and Backoff with Jitter
- Base retry delay: 100ms with exponential backoff
- Maximum retry delay: 30 seconds
- Full jitter: delay = random(0, min(cap, base * 2^attempt))
- Per-client retry limits based on tier (free: 3, paid: 5, enterprise: 10)
- Circuit breaker opens after 5 consecutive failures

## Queue Management
- Trim oldest requests when queue exceeds capacity
- Preserve high-priority requests (authenticated, paid tiers)
- Background job queue separate from real-time requests
- Dead letter queue for failed requests requiring manual review

## Load Shedding Thresholds
- CPU >80%: Enable basic load shedding (non-essential features)
- CPU >90%: Aggressive load shedding (see load-shedding.md)
- Memory >85%: Reduce cache sizes and background processing
- GPU >95%: Queue LLM requests, scale down batch size

## Cross-References
- Chapter 6 sandbox policy for network isolation during overload
- load-shedding.md for feature disabling procedures
- rate_limits.yaml for per-tenant throttling configuration