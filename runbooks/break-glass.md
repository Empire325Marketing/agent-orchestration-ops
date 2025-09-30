# Runbook — Break-Glass Emergency Access

## Step 1: Request Initiation
- Incident commander creates break-glass request ticket
- Document reason, scope, and expected duration
- Specify which systems require emergency access
- Link to active incident ticket

## Step 2: Dual Approval
- Request sent to two authorized approvers from different teams
- Both approvers must validate within 15 minutes
- Approval requires MFA authentication
- Rejection by either approver blocks the request

## Step 3: Time-Boxed Policy Attachment
- Upon dual approval, break-glass role activated
- Maximum duration: 24 hours (auto-revoke)
- Session recording enabled for all actions
- High-priority audit logging activated

## Step 4: Emergency Actions
- Execute required emergency procedures
- All commands logged with full context
- Real-time alerts to security team
- Continuous monitoring of scope compliance

## Step 5: Revocation
- Automatic revocation at time limit
- Manual early revocation when incident resolved
- All active sessions immediately terminated
- Credentials rotated for affected systems

## Step 6: Postmortem and Audit
- Mandatory postmortem within 48 hours
- Review all actions taken under break-glass
- Document lessons learned and process improvements
- Update DECISIONS.log with incident reference

## Audit Entry Format
```
<TIMESTAMP> | OPERATOR=<requester> | ACTION=break_glass_activated | INCIDENT=<ticket> | DURATION=<hours> | APPROVERS=<name1,name2>
<TIMESTAMP> | OPERATOR=<requester> | ACTION=break_glass_revoked | INCIDENT=<ticket> | ACTIONS_COUNT=<n> | POSTMORTEM=<link>
```