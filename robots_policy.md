# Robots.txt Policy

## Fetch Behavior
- Always fetch /robots.txt once per host per 24 hour period
- Cache robots.txt responses to minimize repeated requests

## Compliance Rules
- Disallow access if user agent section denies our USER_AGENT or wildcard "*"
- Respect crawl-delay directives when specified
- Honor sitemap references for discovery optimization

## Logging Requirements
- Log robots outcome on every request attempt
- Track compliance metrics for audit purposes
- Record any robots.txt parsing errors or ambiguities

## Fallback Handling
- If robots.txt unavailable due to 4xx or 5xx errors, treat as allow=false
- Exception: domains explicitly allow-listed with override tag "robots:ignore=false" still honor robots.txt
- No override mechanism exists to completely ignore robots.txt compliance