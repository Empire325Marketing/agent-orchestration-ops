# Role Change Workflow

## Principle
All role changes follow least-privilege and require approval from someone with higher privileges.

## Request Process

### 1. Initiate Request
- Requestor submits role change via approved channel (ticket system, email to security team)
- Required info: user_id, current_roles, requested_roles, business_justification, duration (if temporary)
- Manager or project lead endorsement required for privilege escalation

### 2. Approval Matrix
| Current Role | Requested Role | Approver Required |
|--------------|----------------|-------------------|
| viewer → developer | Project admin+ | 
| developer → admin | Org owner |
| admin → owner | Current org owner + security team |
| Any → owner | Dual approval: current owner + C-level |

### 3. Review Criteria
- [ ] Business need clearly documented
- [ ] Requestor has completed security training (if escalating)
- [ ] No security incidents associated with user in last 6 months
- [ ] Temporary access has defined end date and review
- [ ] Conflicts of interest evaluated (e.g., developer auditing own code)

## Implementation Steps

### 4. Execute Change
```sql
-- Example role change (documentation only)
-- UPDATE role_bindings 
-- SET role = 'admin', granted_by = '<approver_id>', modified_at = now()
-- WHERE user_id = '<user_id>' AND resource_id = '<project_id>';

-- Log the change
-- INSERT INTO access_audit_log (user_id, action, old_role, new_role, approver, reason)
-- VALUES ('<user_id>', 'role_change', 'developer', 'admin', '<approver>', '<justification>');
```

### 5. Notification
- [ ] Notify user of role change and new permissions
- [ ] Update team access documentation
- [ ] Brief user on additional responsibilities if privilege escalation
- [ ] Schedule review date for temporary access

### 6. Verification
- [ ] User confirms they can access newly granted resources
- [ ] User confirms they cannot access revoked resources
- [ ] Monitor for appropriate usage in first 30 days

## Rollback Procedure
If role change causes issues:
1. Immediately revert to previous role assignment
2. Investigate root cause (config error vs. user error vs. system issue)
3. Document incident and lessons learned
4. Re-execute change process with corrections if needed

## Monitoring
- Track role changes in authz metrics (privileged actions by recently changed users)
- Alert on rapid role escalations (multiple changes in short period)
- Quarterly review of all role changes for patterns

## DECISIONS.log Entry
```
<TIMESTAMP> | OPERATOR=<approver> | ACTION=role_change | USER=<user_id> | FROM=<old_role> | TO=<new_role> | RESOURCE=<scope> | JUSTIFICATION=<reason> | EXECUTOR=<system>
```
