# Runbook — Compliance Audit

## Step 1: Locate Compliance Artifacts
- Verify presence of all required compliance documentation
- Check jurisdiction_matrix.yaml for completeness and accuracy
- Confirm DPIA and AI Act post-market plan are current
- Validate cross-references to existing deletion and legal-hold runbooks

## Step 2: Verify Matrix Freshness
- Review last update dates on all jurisdiction matrices
- Confirm retention periods align with current legal requirements
- Check for new jurisdictions or regulatory changes since last review
- Validate legal basis citations are current and accurate

## Step 3: Sample Deletion Proofs
- Select random sample of completed deletion operations from past quarter
- Verify deletion proof artifacts (CSV/JSON) contain required data
- Confirm deletion operations followed appropriate runbook procedures
- Check legal hold verification was performed before deletion
- Validate audit trail completeness for sampled deletions

## Step 4: Review AI Act Compliance
- Examine post-market monitoring metrics for compliance thresholds
- Verify bias detection and incident response procedures are operational
- Check notification timelines for any reported incidents
- Confirm human oversight controls are functioning as designed

## Step 5: Validate Access Controls
- Review service identity permissions against documented roles
- Confirm least-privilege access principles are maintained
- Check Vault role assignments match service requirements
- Verify break-glass procedures have not been inappropriately activated

## Step 6: Produce Audit Report
- Document findings, exceptions, and recommendations
- Calculate compliance scores for each reviewed area
- Identify required remediation actions with timelines
- Prepare executive summary with risk assessment

## Step 7: Record Audit Completion
- Append DECISIONS.log entry with audit completion timestamp
- Reference audit report location and key findings
- Schedule follow-up actions and next audit cycle
- Notify stakeholders of audit results and required actions

## Audit Entry Format
```
<TIMESTAMP> | OPERATOR=<auditor> | ACTION=compliance_audit_completed | SCOPE=<areas_reviewed> | FINDINGS=<summary> | REPORT=<location> | NEXT_AUDIT=<date>
```

## Frequency and Scope
- **Quarterly**: Full compliance review including all matrices and runbooks
- **Monthly**: Spot checks on deletion operations and access controls
- **Annual**: Comprehensive AI Act compliance assessment with external review
- **Ad-hoc**: Triggered by regulatory changes or significant incidents