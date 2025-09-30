# Runbook — SOC Incident Response

## Common
1) Acknowledge page, establish bridge, assign roles (Incident Commander, Comms, Scribe).
2) Identify tenant/region/scope; check legal-hold/compliance constraints (Ch.9).
3) Preserve evidence: snapshot relevant audit spans (Ch.31), export copies with hashes.

## Scenarios
### Privilege Escalation
- Contain: suspend token/session; remove elevated role; open change review.
- Eradicate: rotate affected secrets (Ch.8); audit memberships (access-review.md).
- Recover: validate RBAC policies (policy_checks.md); run postmortem.

### Auth Bruteforce
- Contain: increase backoff; CAPTCHA/step-up; temporary IP blocks via proxy (Ch.6).
- Notify tenant owner; watch residual attempts.

### Cross-Tenant Attempt
- Contain: force deny; review org/project/env bindings; add detections to allowlist exceptions review.

### Prompt Injection
- Contain: apply prompt-firewall-hotfix; run safety tests (Ch.17); stage rollout (Ch.10/26).

### Export Hash Mismatch
- Contain: revoke links; regenerate; run export-verify; document variance.

## Close & Learn
- Update DECISIONS.log with incident_id and summary; schedule postmortem.
