# Secret Rotation Schedule

## Rotation Cadences

### LLM and API Keys
- **Rotation Period**: 30 days
- **Owner**: Platform Operations Team
- **Scope**: All external API keys including OpenAI, Claude, GitHub, search providers
- **Process**: Automated rotation with 7-day overlap period for graceful transition

### Database Credentials
- **Rotation Period**: 60 days
- **Owner**: Database Administration Team
- **Scope**: Postgres primary, read replicas, pgvector extensions, Qdrant credentials
- **Process**: Rolling update with connection pool drainage

### Proxy Keys
- **Rotation Period**: 60 days
- **Owner**: Network Security Team
- **Scope**: Egress proxy authentication, gateway API keys, rate limit tokens
- **Process**: Staged rollout with traffic validation at each stage

### JWT Signing Keys
- **Rotation Period**: 90 days
- **Owner**: Security Operations Team
- **Scope**: Service-to-service authentication, session tokens, refresh tokens
- **Process**: Key versioning with dual-key period for seamless transition

### Break-Glass Tokens
- **Rotation Period**: 24 hours (automatic expiry)
- **Owner**: Incident Response Team
- **Scope**: Emergency access credentials
- **Process**: Time-boxed generation with mandatory revocation

## Rotation Playbook References

See Chapter 5 tool registry (`/srv/primarch/tool_registry.yaml`) for detailed rotation procedures per tool type.

## Compliance Notes

- All rotations must be logged in audit system
- Failed rotations trigger immediate alerts to on-call
- Grace period allows for rollback if rotation causes service disruption
- Quarterly review of rotation periods based on security posture assessment