# Chapter 1 — API Gateway & Orchestrator

## Decision Summary

- **Gateway**: Kong (OSS). Why: plugin ecosystem (auth, rate-limit), quick MVP fit, on-prem.
- **Orchestrator**: Internal MVP orchestrator (service-local queue/handlers). Why: fastest path; later swap to Temporal for durable workflows.

## Alternatives considered

- **Traefik**: Pros - simpler config, good for containers. Cons - fewer enterprise plugins, weaker rate-limiting.
- **Envoy**: Pros - high performance, CNCF standard. Cons - complex config, steeper learning curve for MVP.
- **Temporal now vs later**: Pros - durable workflows, battle-tested. Cons - operational overhead, overkill for MVP simplicity.

## Interfaces (MVP)

- **Public entrypoints**: `/api/v1/chat`, `/api/v1/tools`, `/api/v1/memory` paths.
- **Auth method**: OIDC planned (JWT bearer tokens).
- **Rate-limits**: per tenant (100 req/min default), burst allowance.
- **Error model**: RFC7807 problem details format, structured error codes.
- **Orchestrator responsibilities**: tool invocation lifecycle, retries/backoff, audit log append.

## Non-Goals (MVP)

- Multi-region gateway, complex canary routing, long-running sagas.

## Next actions

- Define tool registry (Chapter 5), DB-as-memory schema (Chapter 2), and sandbox/proxy rules (Chapter 6).