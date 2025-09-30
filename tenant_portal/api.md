# Tenant Portal API (Documentation)

## GET /tenant/audit
- Query: start, end, family?, status?, page?, limit?
- Returns: list of audit items (ts, family, action, status, trace_id, region)
- Notes: Tenant/org scope derived from JWT (Ch.23). Region filter applied (Ch.30).

## POST /tenant/dsr
- Body: { type: access|export|delete|correction, subject_assertion, contact_email }
- Side effects: creates DSR record; appends audit (family=admin_change, action=dsr.open)
- SLA clock starts (see SLAs).

## GET /tenant/dsr/{id}
- Returns state: opened|verifying|processing|ready|delivered|closed|rejected
- If state=ready: files[] with {name, bytes, sha256, signed_url(expiry)}

## GET /tenant/usage-glance
- Returns last 30d totals by meter + cost headroom (Ch.24), redacted for privacy.

### Errors
- 401/403 on RBAC failure; 429 if tenant over budget (Ch.12); 451 if legal-hold prohibits delivery (Ch.9).
