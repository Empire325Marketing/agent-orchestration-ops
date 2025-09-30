# Runbook — Load Shedding

## Feature Dimming Order (Progressive)

### Level 1: Non-Essential Features
1) Disable analytics and usage tracking
2) Reduce background data sync frequency
3) Pause non-critical scheduled jobs
4) Disable optional API endpoints

### Level 2: Enhanced Features
1) Disable vector similarity search (fallback to keyword)
2) Reduce LLM context window to minimum viable
3) Disable multi-model inference (single model only)
4) Pause real-time notifications

### Level 3: Core Feature Reduction
1) Limit concurrent sessions per user
2) Reduce API rate limits across all tiers
3) Disable file upload processing
4) Queue non-urgent requests

### Level 4: Minimum Viable Service
1) Read-only mode for non-critical operations
2) Emergency authentication bypass disabled
3) Disable all background processing
4) Core API only with reduced functionality

## Implementation Steps
1) Assess current system load and user impact
2) Determine appropriate load shedding level
3) Activate feature flags for selected level
4) Update status page with affected features
5) Monitor system recovery and user feedback
6) Gradually restore features as load decreases

## Tie to Brownout Policy
- Follows model brownout procedures from model-brownout.md
- Coordinates with rate limiting from rate_limits.yaml
- Aligns with sandbox network restrictions when needed
- Triggers escalation per incident.md severity levels