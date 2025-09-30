# Runbook — Retry and Backoff

## Idempotency Guidance
- All API operations must be idempotent where possible
- Use idempotency keys for non-idempotent operations
- Database operations wrapped in transactions with conflict resolution
- File operations use temporary files with atomic rename
- External API calls checked for safe retry patterns

## Per-Tool Retry Caps

### Database Operations
- PostgreSQL: 3 retries with 100ms base delay
- Qdrant: 5 retries with 200ms base delay
- Vector operations: 3 retries with 500ms base delay

### External APIs
- GitHub API: 5 retries with 1s base delay
- Search proxy: 3 retries with 300ms base delay
- Weather API: 3 retries with 500ms base delay
- LLM inference: 2 retries with 1s base delay

### Internal Services
- Gateway: 3 retries with 50ms base delay
- Orchestrator: 5 retries with 100ms base delay
- Tool calls: 3 retries with 200ms base delay

## Backoff Algorithm
1) Calculate delay: min(max_delay, base_delay * 2^attempt)
2) Add full jitter: delay = random(0, delay)
3) Check circuit breaker state before retry
4) Log retry attempts with context
5) Fail fast after reaching retry cap

## Circuit Breaker Integration
- Open circuit after consecutive failures exceed threshold
- Half-open state allows single retry attempt
- Close circuit after successful operation
- Per-service circuit breaker state tracking

## Error Classification
- Retryable: 5xx errors, timeouts, connection failures
- Non-retryable: 4xx errors (except 429), authentication failures
- Rate limiting (429): Respect Retry-After header
- Quota exceeded: Exponential backoff with longer delays