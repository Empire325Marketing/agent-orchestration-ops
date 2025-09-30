# Chapter 6 — Sandbox & Proxy Policy (MVP)

## Decision Summary
Network default is OFF for sandboxed tools with outbound access only via proxy with allow-list. Proxy mode has egress pinned to allow-list domains with per-call crawl budgets and robots.txt compliance. Egress logging ensures every request emits an OTel span with attributes including tool_name, tenant_id, url_host, status_code, bytes, latency_ms, and robots_respected flag.

## Allow/Block Rules
Allow-list includes default domains such as github.com, api.github.com, docs.*, and vendor APIs. Block-list covers credentials sites, private IP ranges per RFC1918, link-shorteners, and untrusted file hosts. Content-type allow-list permits text/html, text/plain, application/json, and application/pdf while denying everything else.

## Budgets & Limits
Crawl budget per call enforces MAX_PAGES=10, MAX_DEPTH=1, MAX_BYTES=10MB, MAX_TIME=30s, and RATE≤1 rps/host. Retries use exponential backoff with full jitter and MAX_RETRIES=3. Size and time cutoffs produce graceful partial results with truncated=true flag.

## Safety & Compliance
Injection guard refuses pages containing patterns like "ignore instructions", "act as system", or hidden prompts. PII and region routing labels queries as none, low, or high, with high+region=EU/CN enforcing regional provider or denial. Robots and ToS compliance obeys robots.txt, returning 403(policy) and logging when disallow rules are matched.

## Operator Controls
Allow-list overlays support per-tenant files in allowlist.d/ directory while blocklist.d/ maintains higher priority. Environment knobs include PROXY_URL, ALLOW_LIST, BLOCK_LIST, CRAWL_BUDGET, USER_AGENT, and REGION_POLICY for operational control.

## Done-when
Policy files exist including sandbox_policy.md, proxy_allowlist.txt, and robots_policy.md. Runbooks exist for sandbox-escape.md and proxy-outage.md scenarios. The .env.sandbox.example configuration template is available. PROJECT_STATUS shows Chapter 6 checked. DECISIONS.log has a new timestamped Chapter 6 entry.