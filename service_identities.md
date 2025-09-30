# Service Identities and Role Assignments

## Gateway Service
- **Identity**: gateway-service
- **Running As**: System service account with network capabilities
- **IAM Role**: gateway-proxy-keys
- **Access Needed**:
  - Read proxy authentication credentials
  - Read rate limit configurations
  - Read JWT validation keys
- **Justification**: Gateway must authenticate outbound requests and validate incoming tokens

## Orchestrator Service
- **Identity**: orchestrator-service
- **Running As**: Application service account
- **IAM Role**: orchestrator-read-secrets
- **Access Needed**:
  - Read API keys for external services
  - Read LLM model credentials
  - Read vector store authentication
- **Justification**: Orchestrator coordinates all tool calls and needs credentials for service integrations

## Worker Service
- **Identity**: worker-service
- **Running As**: Background job processor account
- **IAM Role**: None (receives credentials via job context)
- **Access Needed**:
  - Temporary credentials passed per job
  - No persistent secret access
- **Justification**: Workers operate on delegated credentials to minimize attack surface

## LLM Runtime Service
- **Identity**: llm-runtime-service
- **Running As**: GPU-enabled service account
- **IAM Role**: Read-only subset of orchestrator-read-secrets
- **Access Needed**:
  - Read model API keys
  - Read model weight encryption keys
  - Read inference optimization configs
- **Justification**: LLM runtime needs model credentials but not general API keys

## Vector Client Service
- **Identity**: vector-client-service
- **Running As**: Data processing service account
- **IAM Role**: Read-only for vector paths
- **Access Needed**:
  - Read Qdrant authentication
  - Read pgvector credentials
  - Read embedding model keys
- **Justification**: Vector operations require database access for similarity search

## Telemetry Collector
- **Identity**: telemetry-collector
- **Running As**: Monitoring service account
- **IAM Role**: telemetry-exporter
- **Access Needed**:
  - Read observability API keys
  - Read metrics push gateway credentials
  - Read trace export authentication
- **Justification**: Telemetry must authenticate to external monitoring systems

## Security Principles
- Each service runs with minimal required privileges
- Service accounts cannot assume other service roles
- Cross-service communication uses mutual TLS
- Credential exposure limited to service boundary
- Regular audit of unused permissions for removal