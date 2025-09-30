# Golden Dashboards Guide

## Service Overview Dashboard
Required metrics and labels: requests_total{service}, errors_total{service}, request_duration_ms{service}
How to read: Monitor overall service health by tracking request rates, error rates, and latency percentiles (p50/p95/p99) across all services to quickly identify degraded components.

## GPU Pool Performance Dashboard
Required metrics and labels:
- llm_pool_latency_ms{pool}, histogram_quantile(0.95, llm_pool_latency_ms{pool})
- llm_queue_depth{pool}, llm_requests_inflight{pool}
- gpu_utilization_percent{pool}, gpu_memory_usage_percent{pool}
- llm_pool_requests_total{pool}, llm_pool_errors_total{pool}

How to read: Monitor per-pool performance with dedicated panels for:
- **Pool A/B/C P95 Latency**: Compare RTX 5090 pools (A,B) vs RTX 3090 (C) performance
- **Queue Depth by Pool**: Track request queuing and backpressure per pool
- **GPU Utilization by Pool**: Monitor VRAM and compute utilization per pool
- **Pool Status Indicators**: Visual alerts when any pool enters "hot" state (>85% utilization)

## Pool Hot State Alerts
Required alerts:
- Pool A Hot: gpu_utilization_percent{pool="A"} > 85 for 5 minutes
- Pool B Hot: gpu_utilization_percent{pool="B"} > 85 for 5 minutes
- Pool C Hot: gpu_utilization_percent{pool="C"} > 80 for 5 minutes
- Queue Depth Critical: llm_queue_depth{pool} > 50 for 2 minutes

How to read: Immediate visual and audible alerts when any GPU pool approaches resource limits, triggering load balancing and traffic routing decisions.

## Tail Latency Deep-Dive Dashboard
Required metrics and labels: request_duration_ms{route,tool,provider,pool}, histogram_quantile for p95/p99
How to read: Analyze high-percentile latencies broken down by route, tool, provider, and GPU pool to identify specific slow operations and optimize critical paths.

## Saturation Dashboard
Required metrics and labels: cpu_usage_percent, gpu_usage_percent{pool}, memory_usage_bytes, disk_io_bytes, network_bytes{direction}
How to read: Track resource utilization approaching limits (80% warning, 90% critical) to proactively scale or optimize before saturation causes failures.

## Cost per Request Dashboard
Required metrics and labels: llm_tokens_total{model,type,pool}, vector_operations_total{operation}, egress_bytes_total, cost_per_request_usd{pool}
How to read: Monitor operational costs per request including LLM token consumption per pool, vector operations, and egress bandwidth to identify cost optimization opportunities.

## Trace Coverage & Sampling Dashboard
Required metrics and labels: traces_sampled, requests_total, sampling_decisions{policy}, trace_spans_per_request
How to read: Verify trace coverage stays above 95% SLO and monitor sampling policy effectiveness to ensure observability completeness while managing overhead.