# Chapter 23 — Multi-Tenancy & RBAC

## Decision Summary
We enforce a hierarchical org→project→env→role model with JWT claims mapped to permissions. Authorization decisions use API gateway + orchestrator middleware + Postgres RLS policies. All authz decisions are traced for audit.

## Scope (MVP)
- Data model: tenants/orgs, projects, envs, users, memberships, role_bindings
- Roles: owner, admin, developer, analyst, viewer with least-privilege matrix
- AuthZ flows: request → JWT parse → policy check → DB RLS enforcement
- Audit trail: all authorization decisions logged with trace correlation
- Cost isolation per org/project for billing (Ch.12 integration)

## Non-Goals
- External IdP integration (Auth0, OIDC) deferred to post-MVP
- Cross-org resource sharing or federation
- Dynamic role creation (fixed set: owner/admin/developer/analyst/viewer)

## Data Model Overview
Tables (documentation only; schema in separate docs):
- `orgs`: org_id, name, tier, legal_hold, created_at
- `projects`: project_id, org_id, name, env_configs, created_at  
- `envs`: env_id, project_id, name (dev/staging/prod), config, created_at
- `users`: user_id, email, name, status, created_at
- `memberships`: org_id, user_id, invited_by, status, created_at
- `role_bindings`: user_id, resource_type, resource_id, role, granted_by, created_at

## AuthZ Flows
1) API Gateway: validate JWT signature + basic claims (sub, exp, org_id)
2) Orchestrator middleware: parse full claims → build authz_context → check permission_matrix
3) DB queries: RLS policies filter based on current_setting('app.jwt.claims')
4) Observability: trace annotation with authz decisions (allow/deny + reason)

## Ties
- **Ch.6 Sandbox/Proxy**: network isolation per org/project
- **Ch.7 Observability**: authz metrics + alerts for anomalies  
- **Ch.8 Secrets/IAM**: JWT signing keys in Vault; rotation policy
- **Ch.10 CI/CD**: deployment permissions per env (dev < staging < prod)
- **Ch.12 Cost**: billing isolation and budget enforcement per org
- **Ch.13 Readiness**: role-based promotion gates (only admins promote to prod)
- **Ch.14 Risks**: access review quarterly; insider threat monitoring
- **Ch.16 Data Quality**: lineage visibility scoped by role permissions
- **Ch.17 Safety**: safety test results visible to safety-authorized roles only
