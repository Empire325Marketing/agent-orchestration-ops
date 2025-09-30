# JWT Claims Specification

## Required Claims
- `sub`: User ID (string, matches users.user_id)
- `org_id`: Primary organization ID (string)
- `project_ids`: Array of accessible project IDs (string[])
- `env`: Current environment context (string: "dev"|"staging"|"prod")
- `roles`: Array of roles within scope (string[]: "owner"|"admin"|"developer"|"analyst"|"viewer")
- `scopes`: Resource scopes for this session (string[])
- `tenant_tier`: Billing tier (string: "free"|"pro"|"enterprise")
- `legal_hold`: Legal hold flag (boolean, blocks certain deletions)

## Standard JWT Claims
- `iss`: Issuer (primarch-auth)
- `aud`: Audience (primarch-api)
- `exp`: Expiration (≤ 1h from iat)
- `iat`: Issued at timestamp
- `jti`: Unique token ID for revocation

## Validation Rules
- Clock skew tolerance: ±30 seconds
- Token lifetime: ≤ 1 hour (force refresh)
- Org membership: org_id must exist in user's memberships
- Project access: project_ids must be subset of user's accessible projects
- Role consistency: roles must match role_bindings for the resources

## Mapping Examples

### Developer Access Check
```
JWT: {
  "sub": "user123",
  "org_id": "org456", 
  "project_ids": ["proj789"],
  "env": "dev",
  "roles": ["developer"],
  "scopes": ["project:proj789:dev:write"]
}

Permission check for POST /v1/assist:
- Action: "write" ✓ (developer has write)
- Resource: "project:proj789" ✓ (in project_ids)
- Environment: "dev" ✓ (matches env claim)
Result: ALLOW
```

### Admin Prod Deployment
```
JWT: {
  "sub": "admin456",
  "org_id": "org456",
  "project_ids": ["proj789", "proj101"],
  "env": "prod", 
  "roles": ["admin"],
  "scopes": ["project:*:prod:admin"]
}

Permission check for POST /deploy/prod:
- Action: "run_jobs" ✓ (admin has run_jobs)
- Resource: "env:prod" ✓ (admin can access prod)
Result: ALLOW
```
