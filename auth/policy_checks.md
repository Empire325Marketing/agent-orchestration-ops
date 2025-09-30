# Authorization Policy Checks

## Middleware Flow (Pseudocode)

```pseudocode
function checkAuthorization(request, jwt_claims, resource, action):
    // 1. Build authorization context
    authz_context = {
        user_id: jwt_claims.sub,
        org_id: jwt_claims.org_id,
        project_ids: jwt_claims.project_ids,
        environment: jwt_claims.env,
        roles: jwt_claims.roles,
        scopes: jwt_claims.scopes,
        tenant_tier: jwt_claims.tenant_tier,
        legal_hold: jwt_claims.legal_hold
    }
    
    // 2. Load permission matrix for user roles
    allowed_actions = []
    for role in authz_context.roles:
        role_perms = permission_matrix.roles[role].permissions
        allowed_actions.extend(role_perms)
    
    // 3. Check action permission
    if action not in allowed_actions:
        trace.annotate(authz_decision="deny", reason="insufficient_role")
        return AuthzResult.DENY("Action not permitted for roles: " + roles)
    
    // 4. Check resource scope
    resource_allowed = false
    for role in authz_context.roles:
        scopes = permission_matrix.roles[role].resource_scopes
        if resource_matches_any_scope(resource, scopes, authz_context):
            resource_allowed = true
            break
    
    if not resource_allowed:
        trace.annotate(authz_decision="deny", reason="resource_out_of_scope")
        return AuthzResult.DENY("Resource not in permitted scope")
    
    // 5. Environment restrictions
    if resource.env and resource.env not in get_permitted_envs(authz_context):
        trace.annotate(authz_decision="deny", reason="env_restricted")
        return AuthzResult.DENY("Environment access denied")
    
    // 6. Legal hold restrictions
    if authz_context.legal_hold and action in ["delete", "purge"]:
        trace.annotate(authz_decision="deny", reason="legal_hold_active")
        return AuthzResult.DENY("Legal hold prevents deletion")
    
    // 7. Success - annotate trace and allow
    trace.annotate(
        authz_decision="allow",
        user_id=authz_context.user_id,
        org_id=authz_context.org_id,
        roles=authz_context.roles,
        action=action,
        resource=resource
    )
    
    return AuthzResult.ALLOW()

function resource_matches_any_scope(resource, scopes, context):
    for scope in scopes:
        if scope == "org:*" and resource.org_id == context.org_id:
            return true
        elif scope == "project:*" and resource.project_id in context.project_ids:
            return true
        elif scope == "project:assigned" and resource.project_id in context.project_ids:
            return true
        elif scope matches resource pattern:
            return true
    return false
```

## Error Codes and Responses

### 403 Forbidden Responses
```json
{
  "error": "forbidden",
  "message": "Insufficient permissions",
  "code": "AUTHZ_DENIED",
  "trace_id": "trace123",
  "details": {
    "required_action": "write",
    "required_scope": "project:proj789",
    "user_roles": ["viewer"],
    "hint": "Contact admin to request developer role"
  }
}
```

### Redaction Rules
- Never expose other users' data in error messages
- Don't reveal existence of resources user cannot access
- Generic "not found" for authz failures on specific resources
- Trace IDs for debugging but no sensitive claims in logs

## Database Query Annotation

Before executing queries, set JWT claims in session:
```sql
-- Set claims for RLS policies
SELECT set_config('app.jwt.claims', %jwt_claims_json%, true);

-- Execute user query with RLS automatically applied
SELECT * FROM messages WHERE project_id = %project_id%;
```

The RLS policies will automatically filter results based on the JWT claims.
