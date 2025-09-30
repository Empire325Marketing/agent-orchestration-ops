# Sandbox Policy (MVP)

## Execution Isolation
- Execution isolation enforces filesystem read-only access except for /tmp directory
- No device access permitted within sandbox environment
- No shelling-out to network connections allowed

## Network Controls
- Network default is OFF with proxy-only egress permitted
- DNS resolution locked to proxy server only

## File I/O Rules
- Maximum file size limit of 25MB per file
- Deny writing outside designated WORKDIR
- Temporary file time-to-live set to 24 hours

## Data Handling
- Redact secrets and PII before persistence to storage
- Log only hashed identifiers for audit purposes

## Deny List
- Private IP addresses per RFC1918 ranges blocked
- Link-shorteners and URL redirectors denied
- Pastebins and file-sharing sites blocked unless explicitly allow-listed

## Incident Response
- Any policy violation triggers sandbox-escape runbook execution
- Immediate quarantine and investigation procedures activated