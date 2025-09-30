# Chapter 26 — Prompt Firewall & Persona SDK: FRANK

## Decision Summary
We implement a multi-layer prompt firewall (PromptGuard v2) with persona-aware routing and the FRANK persona SDK. The firewall enforces security policies at multiple checkpoints while personas provide consistent AI character behaviors and capabilities.

## Scope (MVP)
- **Prompt Firewall**: PromptGuard v2 with pre/post processing filters
- **FRANK Persona**: Complete persona SDK with voice, directives, knowledge base
- **Security Layers**: jailbreak detection, PII filtering, command injection prevention
- **Tool Registry Integration**: firewall-aware tool permissions and egress controls
- **Observability**: real-time monitoring of firewall blocks and persona drift
- **Change Control**: gated rollouts for persona updates and firewall rule changes

## Non-Goals
- Multiple persona support (FRANK-only for MVP)
- Custom persona creation (fixed FRANK implementation)
- Real-time firewall rule learning (static configuration)
- Cross-session persona memory (stateless per conversation)

## Enforcement Order
The security and persona pipeline processes requests in this order:

1. **System Policy**: Global rate limits, tenant permissions (Ch.23 RBAC)
2. **Prompt Firewall (Pre)**: Input validation, jailbreak detection, PII filtering
3. **Persona Card**: FRANK voice, directives, knowledge injection
4. **Tool Registry Caps**: Tool-specific permissions and safety constraints (Ch.5)
5. **Prompt Firewall (Post)**: Output filtering, egress controls, content validation
6. **Safety Evals**: Final safety assessment against curated test sets (Ch.17)

## FRANK Persona Components
- **Voice & Personality**: Communication style, tone, interaction patterns
- **Core Directives**: Fundamental behavior rules and ethical guidelines
- **Knowledge Base**: Domain expertise and factual knowledge corpus
- **Intro Starters**: Conversation initiation templates and examples
- **Summoning Prompt**: System prompt for LLM initialization
- **Command History**: Interaction patterns and response examples

## Prompt Firewall Layers

### Input Firewall (Pre-processing)
- **Jailbreak Detection**: Pattern matching for prompt injection attempts
- **PII Scrubbing**: Identify and mask personally identifiable information
- **Command Injection**: Detect shell commands, SQL injection, code execution
- **Data Exfiltration**: Prevent unauthorized data access attempts
- **Tool Abuse**: Validate tool usage against approved patterns

### Output Firewall (Post-processing)
- **Content Validation**: Ensure responses align with persona guidelines
- **Egress Controls**: Enforce network restrictions (Ch.6 proxy allowlist)
- **Information Leakage**: Prevent system information disclosure
- **Safety Verification**: Cross-check against safety evaluation criteria

## Ties to Other Chapters
- **Ch.6 Network/Proxy**: Egress controls enforced through proxy allowlist
- **Ch.7 Observability**: Real-time metrics on firewall blocks and persona usage
- **Ch.10 CI/CD**: Automated testing of firewall rules and persona changes
- **Ch.12 Cost**: Resource usage monitoring for firewall processing overhead
- **Ch.13 Readiness**: Firewall coverage gates for production deployments
- **Ch.17 Safety Evals**: Integration with safety test harness for validation
- **Ch.23 RBAC**: Permission-aware firewall rules based on user roles

## Security Model
- **Defense in Depth**: Multiple independent security layers
- **Fail-Safe Defaults**: Block unknown or suspicious patterns
- **Audit Trail**: Complete logging of all firewall decisions
- **Real-time Monitoring**: Immediate alerts on security events
- **Regular Updates**: Continuous improvement of detection patterns

## Persona Lifecycle
1. **Asset Ingestion**: Import FRANK knowledge and configuration files
2. **Registry Update**: Version and catalog persona components
3. **Validation**: Verify persona consistency and safety
4. **Deployment**: Gradual rollout with monitoring
5. **Monitoring**: Track persona effectiveness and user satisfaction
6. **Updates**: Controlled changes with rollback capabilities

## Firewall Configuration
- **Global Settings**: Maximum input length, allowed tools, egress policies
- **Detection Rules**: Pattern matching for various threat categories
- **Action Policies**: Block, mask, route to safe model, or human review
- **Persona Profiles**: Customized firewall settings per persona
- **Threshold Tuning**: Sensitivity adjustment based on risk tolerance
