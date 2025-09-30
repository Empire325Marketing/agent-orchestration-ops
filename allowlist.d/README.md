# Allowlist Overlay Directory

## Purpose
This directory contains per-tenant allowlist overlay files that extend the base proxy_allowlist.txt with additional permitted domains.

## File Format
- One hostname per line
- Comments start with # character
- Wildcard patterns using * are supported (e.g., *.example.com)
- Files should be named descriptively (e.g., tenant_123_research.txt)

## Merge Behavior
- All .txt files in this directory are merged with the base allowlist
- Union operation combines all allowed domains
- Duplicate entries are automatically deduplicated

## Precedence Rules
- Base proxy_allowlist.txt provides foundation allowlist
- allowlist.d/*.txt files extend the allowed domains
- blocklist.d/*.txt files have higher priority and override allowlist entries
- If a domain appears in both allowlist and blocklist, blocklist wins

## Security Notes
- Tenant-specific files should be reviewed before deployment
- Wildcard patterns require extra scrutiny for security implications
- Monitor usage patterns to identify potential abuse