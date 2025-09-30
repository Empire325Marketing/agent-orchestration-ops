# Instrumentation Checklist

## SDKs to Enable
- Gateway service: OpenTelemetry SDK for HTTP server instrumentation
- Orchestrator service: OpenTelemetry SDK with workflow tracing
- Worker services: OpenTelemetry SDK with background job instrumentation
- LLM client: Custom spans for prompt/completion with token counts
- Database client: Auto-instrumentation for query tracing with SQL sanitization
- Vector store client: Custom spans for similarity search operations

## Required Span Attributes
All spans must include:
- service.name: Identifying the originating service
- tenant_id: Multi-tenant isolation and analysis
- route: API endpoint or operation path
- tool_name: When applicable, the tool being invoked
- model_id: For LLM operations, the model identifier
- status: Success/failure/timeout status code
- bytes: Request/response size for bandwidth tracking
- latency_ms: Operation duration in milliseconds

## Error Mapping Rules
- HTTP 5xx responses: Map to span status ERROR with http.status_code attribute
- Tool failures: Set span status ERROR with tool.error.type attribute
- Timeout errors: Set span status ERROR with timeout.duration_ms attribute
- Rate limit errors: Set span status ERROR with ratelimit.limit and ratelimit.remaining
- Database errors: Set span status ERROR with db.error.code attribute

## Log Correlation Requirements
- Every log entry must include trace_id field for correlation
- Every log entry must include span_id field for precise correlation
- Use structured logging with consistent field names
- Include severity level mapping to span events

## Sampling Header Preservation
- Preserve W3C traceparent header across all service boundaries
- Maintain tracestate for vendor-specific context
- Propagate sampling decision through async job queues
- Include baggage headers for cross-cutting concerns like tenant_id