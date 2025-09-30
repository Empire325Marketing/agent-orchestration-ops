# Chapter 4 — On-prem LLM Runtime (baseline model, context, quant, limits)

## Decision Summary
Runtime for MVP will use vLLM for ease of deployment and fast iteration. The performance upgrade path involves TensorRT-LLM, kept for capacity tuning later. The baseline local model is Llama 3.1 8B Instruct, an open-weight model. Context target is 32k tokens for MVP, with a roadmap to 64k+ after evaluation. Quantization uses AWQ for MVP with FP8 alternative noted. Failovers include GPT-4o and Claude 3.5 Sonnet as policy documentation only with no cloud calls in this chapter.

## Why this choice
vLLM provides simpler operations, good concurrency, paged key-value caching, and the fastest path to a working MVP. TensorRT-LLM will be adopted later for higher throughput on RTX 5090 if needed post-MVP. The 8B class model fits on a single GPU with headroom for context and key-value storage.

## Model limits & SLOs (targets)
Maximum prompt tokens for MVP is 8k per request. Maximum output tokens for MVP is 1.5k per request. Concurrency window maintains moderate concurrency with backpressure policy enforcement. Latency SLO targets p95 ≤ 1500 ms for short prompts and p95 ≤ 3500 ms for long prompts. Availability SLO for runtime process is ≥ 99.5% during MVP. Budget SLO respects per-tenant limits defined in rate_limits.yaml.

## Safety, privacy, and retention
Local generation only with no default outbound data transfer. No retain policy at application layer with logs and traces redacting PII fields. Prompts and outputs are tagged with tenant_id and pii_flags, with retention following retention_matrix.yaml specifications.

## Observability & telemetry
Emit spans around prompt construction, generation, and streaming phases. Metrics include requests, tokens_in, tokens_out, p50/p95 latency, rate_limited count, and failures. Attributes encompass tenant_id, route, model_id, quantization, and context_target.

## Brownout & overload behavior
On overload, reduce max_output_tokens, disable tools, lower temperature, and tighten rate limits. On burn-rate breach, block long-context requests and downgrade to lighter prompts.

## Rollback & failover basics
Rollback involves reverting to last known-good local model configuration on incident. If local runtime is down, route to secondary local model or cloud per routing policy while honoring region and PII constraints.

## Test & acceptance
Functional testing uses small prompt corpus per tenant to verify limits are enforced. Performance testing involves sample load to ensure p95 targets at low to moderate QPS. Compliance testing verifies PII redaction in logs and trace filtering.

## Done-when
The model_policy.md, llm_routing_policy.md, rate_limits.yaml, runbooks/model-rollback.md, and runbooks/model-brownout.md files exist and align. PROJECT_STATUS shows Chapter 4 checked. DECISIONS.log has a new timestamped entry for Chapter 4.