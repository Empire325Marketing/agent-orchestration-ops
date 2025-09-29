# KPI Tree (MVP)

## North Star
- Reliable, safe answers at sustainable cost

## Core KPIs
1) **Win Rate (golden set)** — target ≥ 0.90
2) **Latency p95 (API/LLM)** — targets: API ≤ 950ms; short LLM ≤ 1500ms; long LLM ≤ 3500ms
3) **Error Rate** — ≤ 1.25× baseline during canary
4) **Safety Rates** — jailbreak_rate = 0; pii_leak_rate = 0; toxicity ≤ 0.01
5) **Cost per Request** — within plan; tenant headroom ≥ 20%
6) **Adoption Funnel** — trial→active→retained (placeholders)

## Ownership
- Product Analytics: funnel metrics
- SRE/Platform: latency, error, availability
- Safety: jailbreak/PII/toxicity
- Finance/Platform: cost metrics

## Inputs
- Prometheus (service/LLM metrics, safety, cost headroom)
- Postgres (messages, tool_calls, costs table)
- OTel traces (coverage ≥ 0.95 over 1h)
