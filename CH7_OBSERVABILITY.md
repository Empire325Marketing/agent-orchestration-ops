# Chapter 7 — Observability (MVP)

## Decision Summary
OTel telemetry uses OTLP over gRPC for traces, metrics, and logs with tail sampling at collector. Golden signals track latency, traffic, errors, saturation, and cost per request for operations. SLOs target availability at 99.9% and latency p95 ≤ 950ms for end-to-end requests. Alerts trigger on multi-window burn with 1h>2x for pages and 6h>1x for warnings, trace coverage below 95%, and p95 latency breaches.

## Scope of Instrumentation
Instrumentation covers Gateway, Orchestrator, Tool calls, DB queries, LLM runtime, Vector store, and Proxy/Egress components. Required span attributes include service.name, route, tenant_id, tool_name, model_id, status, bytes, and latency_ms for comprehensive observability.

## Trace Propagation
W3C traceparent and tracestate headers are required across all services to maintain distributed trace context throughout the request lifecycle.

## Sampling Strategy
Errors are sampled at 100% for complete failure analysis. High latency requests over 800ms are kept at 50% sampling rate. Baseline sampling maintains 10% for normal traffic patterns.

## Metrics
Key metrics include requests_total counter, request_duration_ms histogram, errors_total counter, saturation metrics for CPU/GPU/memory resources, and cost_per_request for operational cost tracking.

## Dashboards & Alerts
Golden dashboards and PromQL alert references are documented in supporting files for operational visibility and incident response. These cover service health, performance, resource utilization, and cost analysis views.

## Done-when
Collector configuration, alert rules, dashboards guide, and runbooks exist for operational readiness. PROJECT_STATUS shows Chapter 7 checked. DECISIONS.log contains the timestamped Chapter 7 entry.