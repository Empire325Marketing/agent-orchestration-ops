# Quarterly Access Review

## Objective
Verify that user access rights follow least-privilege principle and remove stale access.

## Schedule
- Q1, Q2, Q3, Q4 reviews (January, April, July, October)
- Owner: Security/Platform team
- Duration: 2 weeks for review + 1 week for remediation

## Checklist

### Week 1: Data Collection
- [ ] Export current memberships from `orgs`, `users`, `role_bindings` tables
- [ ] Generate access report by org → project → user → roles
- [ ] Flag dormant users (no activity >90 days) via analytics queries
- [ ] Identify privilege escalations since last review
- [ ] Cross-reference with HR systems for departed employees

### Week 2: Review & Decisions  
- [ ] Org owners review their user lists and approve/remove access
- [ ] Platform team reviews admin/owner role assignments
- [ ] Legal team reviews any legal_hold accounts
- [ ] Document access changes needed with justification

### Week 3: Remediation
- [ ] Revoke access for departures and privilege reductions
- [ ] Update role assignments per approved changes
- [ ] Notify affected users of role changes
- [ ] Update DECISIONS.log with review completion

## Export Queries (Read-only)

```sql
-- All active access by org
SELECT 
  o.name as org_name,
  p.name as project_name, 
  u.email,
  u.name as user_name,
  rb.role,
  rb.granted_by,
  rb.created_at,
  u.last_active_at
FROM orgs o
JOIN projects p ON p.org_id = o.org_id  
JOIN role_bindings rb ON rb.resource_id = p.project_id
JOIN users u ON u.user_id = rb.user_id
WHERE u.status = 'active'
ORDER BY o.name, p.name, u.email;

-- Dormant users (>90 days inactive)
SELECT org_id, user_id, email, last_active_at,
       now() - last_active_at as inactive_duration
FROM users 
WHERE last_active_at < now() - interval '90 days'
  AND status = 'active';
```

## Sign-off Requirements
- [ ] Each org owner signs off on their user list
- [ ] Platform team lead approves admin role changes  
- [ ] Security team validates no high-risk access remains
- [ ] Document completion in DECISIONS.log

## DECISIONS.log Entry Format
```
<TIMESTAMP> | OPERATOR=<reviewer> | ACTION=quarterly_access_review | PERIOD=<YYYY-QN> | ORGS_REVIEWED=<count> | USERS_REMOVED=<count> | ESCALATIONS=<count> | STATUS=complete | EXECUTOR=<team>
```
