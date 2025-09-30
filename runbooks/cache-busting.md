# Runbook — Cache Busting

## Safe Invalidation Procedures

### Cache Types and Invalidation
- **Application cache**: Version-based invalidation with gradual rollout
- **Database query cache**: Table-based invalidation on schema changes
- **Vector embedding cache**: Model version-based invalidation
- **API response cache**: Time-based and content-based invalidation
- **CDN cache**: Purge by URL pattern or tag-based clearing

### Invalidation Steps
1) Identify cache scope and dependencies
2) Plan invalidation order to avoid cascade failures
3) Pre-warm critical cache entries before invalidation
4) Execute invalidation in controlled batches
5) Monitor cache hit rates and performance impact
6) Verify data consistency after invalidation

### Safety Checks
- Verify no active transactions depend on cached data
- Confirm downstream services can handle cache misses
- Check that cache rebuilding won't overload backing services
- Ensure monitoring is in place for performance degradation

## Cold Start Mitigation

### Pre-warming Strategy
1) Identify most frequently accessed cache keys
2) Generate cache entries for core user workflows
3) Pre-load model weights and embeddings before traffic
4) Warm up database connections and prepared statements
5) Initialize service dependencies and health checks

### Gradual Warmup
- Start with synthetic load to build initial cache
- Route small percentage of traffic to warm services
- Gradually increase traffic as cache hit rates improve
- Monitor response times during warmup period
- Have rollback plan if performance degrades

### Emergency Procedures
- Temporarily serve stale cache data if backing service fails
- Implement graceful degradation with reduced functionality
- Scale out cache infrastructure during high miss periods
- Use circuit breakers to prevent cache stampede

## Monitoring and Alerts
- Cache hit ratio dropping below 80%
- Increased latency during cache rebuild
- Memory pressure from cache growth
- Failed cache invalidation attempts
- Cold start detection and duration tracking

## Cross-References
- Performance monitoring: observability framework Chapter 7
- Load shedding: runbooks/load-shedding.md for traffic management
- Service scaling: overload.md for capacity management
## Reference
- See Ch.36 policy.md for keys/TTLs
