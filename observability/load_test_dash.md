# Load Test Observability Dashboard

## Key Metrics to Monitor During Load Testing

### 1. API Performance Metrics
- **HTTP Request Duration**: p95 < 950ms (critical threshold)
- **Error Rate**: < 1% failed requests
- **Timeout Rate**: < 0.5% request timeouts
- **Throughput**: Target QPS vs achieved QPS

### 2. System Resource Metrics
- **GPU Utilization**: < 80% on RTX 5090 pools
- **Memory Usage**: RAM and VRAM utilization patterns
- **CPU Load**: Average and peak load per node
- **Network I/O**: Ingress/egress bandwidth utilization

### 3. Queue and Processing Metrics
- **Queue Depth**: Stable, no unbounded growth
- **Task Processing Time**: Agent execution latency
- **Orphaned Tasks**: Zero abandoned or stuck tasks
- **Concurrent Connections**: Active WebSocket/HTTP connections

### 4. vLLM Specific Metrics
- **Batch Size**: Optimal batching efficiency
- **Token Generation Rate**: Tokens/second per model
- **KV Cache Utilization**: Memory efficiency
- **Model Loading Time**: Cold start performance

### 5. Tracing Coverage
- **Trace Completeness**: ≥ 95% coverage during test window
- **Span Duration**: Breakdown by service component
- **Error Traces**: Failed request trace analysis
- **Exemplar Samples**: Representative slow requests

## Prometheus Queries

```promql
# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# GPU utilization
avg(nvidia_gpu_utilization_percentage) by (instance)

# Queue depth
primarch_agent_queue_depth

# Active connections
sum(nginx_connections_active) by (instance)
```

## Alert Thresholds
- **P95 > 950ms**: Warning
- **P95 > 1500ms**: Critical
- **Error rate > 1%**: Warning
- **Error rate > 5%**: Critical
- **GPU util > 80%**: Warning
- **Queue depth > 100**: Warning

## Dashboard Sections
1. **Overview**: Key SLIs, error budget burn
2. **Performance**: Latency histograms, throughput trends
3. **Resources**: GPU/CPU/Memory utilization
4. **Queues**: Task processing pipeline health
5. **Traces**: Sample traces, error analysis
6. **Alerts**: Active incidents, threshold breaches

## Success Criteria
- All thresholds maintained throughout test duration
- No service degradation or outages
- Clean trace propagation across all components
- Stable resource utilization patterns
