# Chapter 9 — Compliance

## Scope & High-Risk Definition
The compliance framework focuses on HR AI features as high-risk applications under the EU AI Act. This includes automated resume screening, performance evaluation assistance, and employee data processing. High-risk designation triggers enhanced obligations for risk management, data governance, human oversight, and post-market monitoring.

## Success Criteria
Success is measured by the presence of complete jurisdiction matrices covering all applicable record types, filled DPIA and AI Act templates with documented risk assessments, defined thresholds and incident triggers for compliance breaches, and operational runbooks linking to existing deletion, legal-hold, and DSR procedures.

## Compliance Artifacts
- **Jurisdiction Matrix**: `/srv/primarch/compliance/jurisdiction_matrix.yaml` - Expanded coverage of HR record types with legal bases and retention requirements
- **Data Protection Impact Assessment**: `/srv/primarch/compliance/dpia.md` - Risk analysis and mitigation strategies for personal data processing
- **AI Act Post-Market Plan**: `/srv/primarch/compliance/ai_act_post_market.md` - Monitoring and incident response for high-risk AI systems
- **Audit Procedures**: `/srv/primarch/runbooks/compliance-audit.md` - Periodic compliance verification steps

## Cross-References
This chapter builds on the retention matrix from Chapter 2 (`/srv/primarch/compliance/retention_matrix.yaml`) and leverages existing operational runbooks for deletion (`/srv/primarch/runbooks/delete-*.md`), legal holds (`/srv/primarch/runbooks/legal-hold.md`), and data subject requests (`/srv/primarch/runbooks/dsr.md`).