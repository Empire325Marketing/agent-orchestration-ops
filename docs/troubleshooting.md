# Troubleshooting

## Common
- 401/403: Check gateway auth and token scopes.
- 5xx: Inspect traces; see runbooks/overload.md for backoff & shedding.
- Slow: Compare to SLOs; check GPU pool state and cost throttles.

## Safety
- Blocked outputs: See runbooks/safety-incident.md and guardrail-tuning.md.

## Data
- Memory mismatch: Run lineage checks (Ch.16) and reconcile vectors if enabled.
