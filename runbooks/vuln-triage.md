# Vulnerability Triage Runbook

## Initial Response (within 30 minutes)
1. **Assess impact**: Check if vulnerability affects running systems
2. **Determine severity**: Map CVSS score to our severity levels
3. **Identify scope**: Which services, environments, tenants affected
4. **Create tracking**: Open incident if Critical, ticket otherwise
5. **Notify stakeholders**: Security team + affected service owners

## Severity classification
- **Critical (CVSS 9.0-10.0)**: Remote code execution, privilege escalation
- **High (CVSS 7.0-8.9)**: Significant data exposure, authentication bypass
- **Medium (CVSS 4.0-6.9)**: Limited data exposure, denial of service
- **Low (CVSS 0.1-3.9)**: Information disclosure, minor impact

## Containment actions
### Critical/High
- Deploy WAF rules or network ACLs if applicable
- Enable feature flags to disable affected functionality
- Scale down or isolate affected services
- Monitor for exploitation attempts

### Medium/Low
- Increase monitoring and alerting
- Document findings and plan remediation
- Schedule for next patch window

## Documentation requirements
- Record all decisions in audit trail (Ch.31)
- Update vulnerability register with findings
- Create exception request if needed
- Link to related SIEM detections (Ch.33)

## Escalation paths
- **Critical during business hours**: Security team lead + on-call engineer
- **Critical after hours**: Page security on-call + incident commander
- **Exception approval**: CISO or designated security manager
