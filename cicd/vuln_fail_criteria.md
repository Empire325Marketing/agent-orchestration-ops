# Vulnerability CI/CD Fail Criteria

## SBOM & Scan Gates
- **Critical vulnerabilities**: Fail build immediately
- **High vulnerabilities**: Fail unless exception filed
- **License violations**: Fail on copyleft/commercial restrictions
- **No SBOM**: Fail if attestation missing

## Supply chain checks
- **Unsigned artifacts**: Fail if provenance/signature missing
- **Dependency confusion**: Fail on suspicious package names
- **Typosquatting**: Fail on close matches to known packages
- **Age/popularity**: Warn on packages <30 days old or <100 weekly downloads

## Runtime image scans
- **Base image vulnerabilities**: Follow severity SLAs above
- **Secrets in image**: Fail on any detected secrets/keys
- **Privilege escalation**: Fail on setuid binaries or suspicious capabilities

## Override mechanism
- Emergency deployment: Requires dual approval + incident ticket
- Risk acceptance: Pre-approved exception + time-bounded waiver
- Hot patch: Deploy fix within next 24h with tracking
