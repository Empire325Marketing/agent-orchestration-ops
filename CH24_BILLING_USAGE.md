# Chapter 24 — Billing & Usage Metering

## Decision Summary
We implement usage-based billing with 5 core meters (tokens_in/out, tool_calls, images, egress) across 3 tiers (Free/Pro/Enterprise). Real-time metering flows from Gateway → Orchestrator → Usage Events → Daily Rollups → Invoices with automated alerts and dispute workflows.

## Scope (MVP)
- Meters: tokens_in, tokens_out, tool_calls, images_generated, egress_bytes
- Rollups: per tenant per day with late-arriving event handling (6h window)
- Pricing: Free (hard caps), Pro (per-unit + soft caps), Enterprise (custom rates)
- Credits/discounts: promo codes, SLA credits, dispute adjustments
- Alerts: spend spikes, unpaid invoices, missing rollups
- Runbooks: billing incidents, usage disputes

## Non-Goals
- Live payment processing (Stripe/PayPal integration deferred)
- Multi-currency or tax calculation
- Complex billing cycles (monthly only for MVP)
- Reseller/partner billing models

## Data Flow
1. Gateway/Orchestrator emit usage events to Postgres
2. Hourly job aggregates events into daily rollups
3. Monthly job generates invoices from rollups + pricing
4. Payment processor handles collection (external)
5. Disputes trigger recomputation from raw events

## Ties
- **Ch.6 Sandbox/Proxy**: egress metering at proxy layer
- **Ch.7 Observability**: billing metrics and spend alerts
- **Ch.10 CI/CD**: cost-aware deployment gates
- **Ch.12 Cost Guards**: tenant budget enforcement 
- **Ch.13 Readiness**: billing health checks before promotion
- **Ch.21 Support**: billing dispute tickets and SLA credits

## Meters
- **tokens_in**: Input tokens to LLM (attributed to model/tool)
- **tokens_out**: Output tokens from LLM (attributed to model/tool)
- **tool_calls**: External API calls (attributed to tool/route)
- **images_generated**: AI-generated images (attributed to model)
- **egress_bytes**: Data transferred out via proxy (attributed to tenant/route)

## Pricing Tiers
- **Free**: $0 with hard caps (1K tokens/day, 10 tool calls/day, no images)
- **Pro**: $10/month base + usage ($0.10/1M tokens_in, $0.30/1M tokens_out, $0.001/tool_call, $0.02/image, $0.02/GB egress)
- **Enterprise**: Custom pricing with monthly commits and volume discounts

## Credits Model
- Promo codes: percentage or fixed amount credits
- SLA credits: automatic compensation for downtime/latency SLA breaches
- Dispute credits: manual adjustments after usage dispute resolution
