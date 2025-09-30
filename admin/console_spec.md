# Admin Console Spec

## Widgets

### Core System Health
- **Burn Rate (1h, 6h)** → alerts: burn_1h>2x, burn_6h>1x (Ch.7).
- **Latency p95** by route/model (Ch.7).
- **Safety**: jailbreak=0, pii_leak=0; toxicity ≤0.01 (Ch.17).
- **Cost Headroom** per-tenant ≥20% (Ch.12).
- **Readiness Gate** summary (Ch.13).

### Tool Adapter (DW-01)
- **Tool Execution Rate**: Success/error rates by tool type and tenant
- **Tool Latency**: P95/P99 execution times with SLA thresholds (< 10s warning)
- **Active Tools**: Current concurrent executions vs capacity (max 100)
- **Registry Health**: Last reload time, tool count, validation errors
- **Top Tools**: Most used tools by execution count and duration

### Speech I/O (DW-03)
- **ASR Status**: Success rate, processing speed (real-time factor < 0.5)
- **TTS Status**: Success rate, generation latency (P95 < 2s)
- **Speech Usage**: Audio minutes processed per tenant (ASR + TTS)
- **Model Health**: ASR/TTS model loading status and availability
- **Language Breakdown**: Usage by language and voice for capacity planning

### Business Intelligence
- **Billing KPIs**: ARPU, MRR approx, aging (Ch.24).
- **Persona FRANK**: assets_present vs expected (Ch.28).
- **Tool Cost Tracking**: Execution costs by tool type and tenant usage patterns

## Data Sources
- **Core Metrics**: Prometheus rules (observability/*), PG analytic views/queries (analytics/*)
- **Readiness**: Readiness files (readiness/*), speech_gate.md, adapter health checks
- **Safety**: Safety sets (safety/*), tool validation errors, speech content filtering
- **Billing**: Billing rollups (billing/*), tool usage costs, speech processing charges
- **Tools**: Tool registry (tool_specs/*.json), execution logs, performance metrics
- **Speech**: ASR/TTS model metrics, audio processing stats, language detection results

## Widget Layout
```
Row 1: [Burn Rate] [Latency P95] [Safety Status] [Readiness Gates]
Row 2: [Tool Exec Rate] [Tool Latency] [Active Tools] [Speech Status]
Row 3: [Cost Headroom] [Billing KPIs] [Tool Usage Top 5] [Speech Usage]
Row 4: [Registry Health] [Model Health] [Language Breakdown] [FRANK Assets]
```

## Alert Integration
- Tool adapter alerts feed into burn rate calculations
- Speech processing errors count toward safety metrics
- Resource exhaustion (tools/speech) triggers capacity alerts
- Registry/model loading failures trigger operational alerts
