# Patch Policy & SLAs
| Severity  | SLA to Contain | SLA to Remediate | Temporary Mitigations |
|-----------|----------------|------------------|---------------------|
| Critical  | 4 hours        | 48 hours         | WAF rule, network isolation, or feature flag |
| High      | 24 hours       | 7 days           | Config change or compensating control |
| Medium    | 72 hours       | 30 days          | Monitoring increase |
| Low       | 7 days         | 90 days          | Log for next regular patch cycle |

## Patch window schedule
- Production: Tuesdays 02:00-06:00 UTC (monthly for non-critical)
- Staging: Sundays 02:00-06:00 UTC (weekly)
- Emergency: Any time for Critical severity with escalation

## Exception workflow
1. File exception request with business justification
2. Risk assessment by security team
3. Compensating controls defined
4. Approval by CISO or delegate
5. Time-bound waiver (max 30 days, renewable with review)

## Vulnerability lifecycle states
- `new`: Just discovered, not triaged
- `triaging`: Under assessment
- `confirmed`: Verified as affecting our systems
- `mitigated`: Temporary controls in place
- `patching`: Fix in progress
- `resolved`: Patch applied and verified
- `accepted`: Risk accepted with exception
- `false_positive`: Not applicable
