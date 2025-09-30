# Primarch Agent Skills Index

## Overview

The Primarch Agent Skills Index catalogs all available agent capabilities, tools, and execution patterns. This index serves as the authoritative reference for agent planning, capability discovery, and security validation.

## Skill Categories

### Level 1: Core Skills (Always Available)
Basic capabilities available to all agents without restrictions.

### Level 2: Tool Skills (Permission Required)
Advanced capabilities requiring explicit tool access and validation.

### Level 3: System Skills (Admin Only)
Privileged operations requiring elevated permissions and audit logging.

---

## LEVEL 1: CORE SKILLS

### C01: Text Processing & Analysis

#### C01.1: Text Understanding
```yaml
skill_id: "text_understanding"
category: "core"
description: "Analyze and comprehend textual content"
security_level: "safe"
parameters:
  - text: string (max_length: 10000)
  - analysis_type: enum[sentiment, summary, entities, topics]
constraints:
  - no_pii_exposure: true
  - content_filtering: true
examples:
  - "Analyze the sentiment of customer feedback"
  - "Extract key topics from research paper"
trace_requirements: ["input_hash", "analysis_method"]
```

#### C01.2: Text Generation
```yaml
skill_id: "text_generation"
category: "core"
description: "Generate structured text based on requirements"
security_level: "safe"
parameters:
  - prompt: string (max_length: 2000)
  - format: enum[paragraph, list, table, json]
  - length: enum[short, medium, long]
constraints:
  - no_harmful_content: true
  - factual_grounding_required: true
examples:
  - "Generate a summary report in table format"
  - "Create a bulleted list of recommendations"
trace_requirements: ["prompt_hash", "output_format"]
```

#### C01.3: Text Transformation
```yaml
skill_id: "text_transformation"
category: "core"
description: "Transform text between formats and styles"
security_level: "safe"
parameters:
  - input_text: string (max_length: 5000)
  - transformation_type: enum[translate, reformat, simplify, expand]
  - target_format: string
constraints:
  - preserve_meaning: true
  - no_sensitive_data_leakage: true
examples:
  - "Convert technical documentation to plain language"
  - "Reformat data from CSV to JSON structure"
trace_requirements: ["transformation_type", "content_length"]
```

### C02: Data Analysis & Reasoning

#### C02.1: Pattern Recognition
```yaml
skill_id: "pattern_recognition" 
category: "core"
description: "Identify patterns and trends in structured data"
security_level: "safe"
parameters:
  - dataset: object (max_size: 1MB)
  - pattern_type: enum[trend, anomaly, correlation, cluster]
constraints:
  - no_personal_identification: true
  - statistical_validity_check: true
examples:
  - "Identify trending topics in user feedback"
  - "Detect anomalies in system performance data"
trace_requirements: ["data_hash", "pattern_method"]
```

#### C02.2: Logical Reasoning
```yaml
skill_id: "logical_reasoning"
category: "core"
description: "Apply logical reasoning to solve problems"
security_level: "safe"
parameters:
  - premises: array[string] (max_items: 10)
  - reasoning_type: enum[deductive, inductive, abductive]
constraints:
  - logical_consistency_check: true
  - evidence_based_conclusions: true
examples:
  - "Determine root cause from symptom list"
  - "Infer missing requirements from specifications"
trace_requirements: ["reasoning_chain", "conclusion_confidence"]
```

#### C02.3: Mathematical Operations
```yaml
skill_id: "mathematical_operations"
category: "core"
description: "Perform mathematical calculations and analysis"
security_level: "safe"
parameters:
  - expression: string (validated_math_only)
  - precision: integer (default: 2)
  - units: string (optional)
constraints:
  - safe_operations_only: true
  - no_infinite_loops: true
  - resource_bounded: true
examples:
  - "Calculate compound interest over time"
  - "Perform statistical analysis on dataset"
trace_requirements: ["operation_type", "result_magnitude"]
```

### C03: Communication & Collaboration

#### C03.1: Query Understanding
```yaml
skill_id: "query_understanding"
category: "core"
description: "Parse and understand user queries and requests"
security_level: "safe"
parameters:
  - query: string (max_length: 1000)
  - context: object (optional)
constraints:
  - intent_classification_required: true
  - ambiguity_resolution: true
examples:
  - "Understand multi-part questions"
  - "Clarify ambiguous requests"
trace_requirements: ["query_intent", "confidence_score"]
```

#### C03.2: Response Formatting
```yaml
skill_id: "response_formatting"
category: "core"
description: "Format responses according to user preferences"
security_level: "safe"
parameters:
  - content: object
  - format_type: enum[markdown, html, json, plain_text]
  - style: enum[formal, casual, technical, simplified]
constraints:
  - format_validation: true
  - accessibility_compliance: true
examples:
  - "Format technical data as readable report"
  - "Present analysis in executive summary style"
trace_requirements: ["format_type", "content_length"]
```

---

## LEVEL 2: TOOL SKILLS

### T01: Information Retrieval

#### T01.1: Web Search
```yaml
skill_id: "web_search"
category: "tool"
description: "Search the web for current information"
security_level: "monitored"
required_permissions: ["web_access"]
tool_name: "web_search_tool"
parameters:
  - queries: array[string] (max_items: 5)
  - num_results: integer (max: 10)
constraints:
  - content_filtering: true
  - source_verification: required
  - rate_limiting: "10/minute"
security_considerations:
  - "Potential for malicious content exposure"
  - "Rate limiting prevents abuse"
  - "Content filtering active"
examples:
  - "Search for latest market trends"
  - "Find technical documentation"
trace_requirements: ["query_hash", "source_domains", "result_count"]
audit_events: ["search_executed", "sources_accessed"]
```

#### T01.2: Document Retrieval
```yaml
skill_id: "document_retrieval"
category: "tool"
description: "Retrieve and analyze documents from knowledge base"
security_level: "tenant_isolated"
required_permissions: ["document_access"]
tool_name: "rag_retrieval_tool"
parameters:
  - query: string (max_length: 500)
  - document_types: array[string]
  - max_documents: integer (max: 20)
constraints:
  - tenant_isolation: enforced
  - access_control: rbac
  - content_filtering: true
security_considerations:
  - "Tenant data isolation critical"
  - "Access logging required"
examples:
  - "Retrieve policy documents related to query"
  - "Find technical specifications"
trace_requirements: ["tenant_id", "document_ids", "access_level"]
audit_events: ["documents_accessed", "tenant_isolation_verified"]
```

### T02: Communication Tools

#### T02.1: Email Operations
```yaml
skill_id: "email_operations"
category: "tool"
description: "Send and manage email communications"
security_level: "high_risk"
required_permissions: ["email_send", "email_read"]
tool_name: "email_tool"
parameters:
  - action: enum[send, read, search]
  - recipients: array[string] (validated_emails)
  - subject: string (max_length: 200)
  - body: string (max_length: 10000)
constraints:
  - recipient_validation: required
  - content_scanning: true
  - rate_limiting: "5/hour"
  - approval_workflow: conditional
security_considerations:
  - "High potential for spam/abuse"
  - "PII exposure risk"
  - "Approval required for external recipients"
examples:
  - "Send status update to project team"
  - "Search for specific email threads"
trace_requirements: ["recipient_hash", "content_classification", "approval_status"]
audit_events: ["email_sent", "approval_requested", "security_scan_result"]
```

#### T02.2: Slack Integration
```yaml
skill_id: "slack_integration"
category: "tool"
description: "Interact with Slack channels and users"
security_level: "monitored"
required_permissions: ["slack_access"]
tool_name: "slack_tool"
parameters:
  - action: enum[send_message, search_messages, list_channels]
  - channel: string (validated)
  - message: string (max_length: 4000)
constraints:
  - channel_access_verification: required
  - message_filtering: true
  - rate_limiting: "20/hour"
security_considerations:
  - "Channel permission verification"
  - "Message content filtering"
  - "User impersonation prevention"
examples:
  - "Post update to development channel"
  - "Search for project-related discussions"
trace_requirements: ["channel_id", "user_id", "message_classification"]
audit_events: ["message_sent", "channel_accessed", "search_performed"]
```

### T03: Data Processing

#### T03.1: File Processing
```yaml
skill_id: "file_processing"
category: "tool"
description: "Process and analyze uploaded files"
security_level: "high_risk"
required_permissions: ["file_access"]
tool_name: "file_processor_tool"
parameters:
  - file_path: string (validated_path)
  - operation: enum[read, analyze, convert, extract]
  - output_format: string
constraints:
  - file_type_validation: required
  - virus_scanning: mandatory
  - size_limits: "100MB max"
  - sandbox_execution: required
security_considerations:
  - "Malicious file upload risk"
  - "Code injection via file content"
  - "Sandbox isolation required"
examples:
  - "Extract text from PDF documents"
  - "Analyze CSV data for trends"
trace_requirements: ["file_hash", "operation_type", "sandbox_id"]
audit_events: ["file_processed", "security_scan_result", "sandbox_created"]
```

#### T03.2: Database Operations
```yaml
skill_id: "database_operations"
category: "tool"
description: "Query and analyze database information"
security_level: "high_risk"
required_permissions: ["database_read", "database_query"]
tool_name: "database_tool"
parameters:
  - query_type: enum[select, analyze, aggregate]
  - table_name: string (validated)
  - filters: object
constraints:
  - read_only_access: enforced
  - query_validation: required
  - result_size_limits: "10000 rows max"
  - sql_injection_prevention: active
security_considerations:
  - "SQL injection attack vector"
  - "Sensitive data exposure"
  - "Performance impact on production DB"
examples:
  - "Analyze customer satisfaction trends"
  - "Generate usage statistics report"
trace_requirements: ["query_hash", "table_accessed", "result_size"]
audit_events: ["query_executed", "data_accessed", "performance_impact"]
```

---

## LEVEL 3: SYSTEM SKILLS

### S01: Code Execution

#### S01.1: Python Code Execution
```yaml
skill_id: "python_execution"
category: "system"
description: "Execute Python code in sandboxed environment"
security_level: "critical"
required_permissions: ["code_execution", "admin_approval"]
tool_name: "python_sandbox_tool"
parameters:
  - code: string (validated_python)
  - timeout: integer (max: 300)
  - dependencies: array[string] (approved_only)
constraints:
  - docker_isolation: mandatory
  - resource_limits: strict
  - network_isolation: enforced
  - approval_workflow: required
security_considerations:
  - "Arbitrary code execution risk"
  - "Resource exhaustion attacks"
  - "Container escape attempts"
examples:
  - "Analyze data with custom Python script"
  - "Process files with specialized libraries"
trace_requirements: ["code_hash", "container_id", "resource_usage", "approval_id"]
audit_events: ["code_executed", "approval_granted", "container_created", "security_scan"]
approval_chain: ["technical_lead", "security_officer"]
```

#### S01.2: System Commands
```yaml
skill_id: "system_commands"
category: "system"
description: "Execute system-level commands and scripts"
security_level: "critical"
required_permissions: ["system_access", "admin_approval"]
tool_name: "bash_tool"
parameters:
  - command: string (validated_commands_only)
  - working_directory: string (sandboxed_path)
constraints:
  - command_whitelist: enforced
  - sandbox_isolation: mandatory
  - privilege_escalation_prevention: active
  - approval_workflow: required
security_considerations:
  - "System compromise risk"
  - "Privilege escalation attempts"
  - "Data exfiltration potential"
examples:
  - "Run system diagnostics"
  - "Execute approved maintenance scripts"
trace_requirements: ["command_hash", "exit_code", "output_size", "approval_id"]
audit_events: ["command_executed", "approval_granted", "sandbox_created"]
approval_chain: ["system_admin", "security_officer", "cto"]
```

### S02: Infrastructure Operations

#### S02.1: Deployment Management
```yaml
skill_id: "deployment_management"
category: "system"
description: "Manage application deployments and infrastructure"
security_level: "critical"
required_permissions: ["deployment_access", "admin_approval"]
tool_name: "deployment_tool"
parameters:
  - environment: enum[staging, production]
  - application: string (validated_app_name)
  - version: string (semantic_version)
constraints:
  - environment_isolation: enforced
  - rollback_capability: required
  - health_check_validation: mandatory
  - approval_workflow: required
security_considerations:
  - "Production system impact"
  - "Service availability risk"
  - "Data integrity concerns"
examples:
  - "Deploy new version to staging"
  - "Rollback production deployment"
trace_requirements: ["environment", "app_version", "deployment_id", "approval_id"]
audit_events: ["deployment_started", "health_checks_passed", "approval_granted"]
approval_chain: ["lead_engineer", "devops_lead", "cto"]
```

### S03: Data Operations

#### S03.1: Database Administration
```yaml
skill_id: "database_administration"
category: "system"
description: "Perform database administrative operations"
security_level: "critical"
required_permissions: ["database_admin", "admin_approval"]
tool_name: "database_admin_tool"
parameters:
  - operation: enum[backup, restore, optimize, migrate]
  - database: string (validated_db_name)
  - schedule: object (optional)
constraints:
  - backup_verification: required
  - data_integrity_checks: mandatory
  - minimal_downtime: enforced
  - approval_workflow: required
security_considerations:
  - "Data loss risk"
  - "System downtime potential"
  - "Data corruption possibility"
examples:
  - "Create full database backup"
  - "Optimize query performance"
trace_requirements: ["operation_type", "database_name", "operation_id", "approval_id"]
audit_events: ["operation_started", "integrity_verified", "approval_granted"]
approval_chain: ["database_admin", "security_officer", "cto"]
```

---

## SKILL ORCHESTRATION PATTERNS

### Pattern P01: Sequential Execution
```yaml
pattern_id: "sequential_execution"
description: "Execute skills in defined order with error handling"
constraints:
  - max_steps: 10
  - timeout_per_step: 300
  - error_propagation: "stop_on_error"
example_flow:
  - skill: "query_understanding"
  - skill: "web_search"
  - skill: "text_analysis"  
  - skill: "response_formatting"
trace_requirements: ["execution_order", "step_timing", "error_points"]
```

### Pattern P02: Parallel Execution
```yaml
pattern_id: "parallel_execution"
description: "Execute multiple skills concurrently"
constraints:
  - max_parallel: 3
  - timeout_total: 600
  - merge_strategy: "best_effort"
example_flow:
  - parallel:
    - skill: "web_search"
    - skill: "document_retrieval"
    - skill: "database_operations"
  - skill: "pattern_recognition"
trace_requirements: ["parallel_timing", "merge_success", "resource_usage"]
```

### Pattern P03: Conditional Execution
```yaml
pattern_id: "conditional_execution"
description: "Execute skills based on dynamic conditions"
constraints:
  - condition_evaluation: "safe_only"
  - max_branches: 5
  - fallback_required: true
example_flow:
  - skill: "query_understanding"
  - condition: "query_type == 'technical'"
    then: "document_retrieval"
    else: "web_search"
  - skill: "response_formatting"
trace_requirements: ["condition_results", "branch_taken", "fallback_used"]
```

---

## SECURITY POLICIES

### Access Control Matrix

| Skill Level | Admin Approval | Resource Limits | Audit Logging | Sandbox Required |
|-------------|----------------|-----------------|---------------|------------------|
| Core (C**) | No | Soft | Basic | No |
| Tool (T**) | Conditional | Medium | Full | Conditional |
| System (S**) | Required | Strict | Complete | Mandatory |

### Risk Assessment

#### Low Risk Skills
- Text processing and analysis
- Mathematical operations  
- Query understanding
- Response formatting

#### Medium Risk Skills
- Web search and retrieval
- Document processing
- Communication tools
- File processing

#### High Risk Skills
- Database operations
- Code execution
- System commands
- Infrastructure operations

### Approval Workflows

#### Conditional Approval (Tool Skills)
```yaml
triggers:
  - external_recipients: true
  - large_file_processing: ">10MB"
  - database_write_operations: true
approval_required: ["team_lead"]
timeout: "2 hours"
fallback: "deny_request"
```

#### Mandatory Approval (System Skills)
```yaml
triggers:
  - all_system_skills: true
approval_required: ["technical_lead", "security_officer"]
additional_approvers:
  - production_operations: ["cto"]
  - code_execution: ["senior_engineer"]
timeout: "4 hours"
fallback: "deny_request"
```

---

## MONITORING & TELEMETRY

### Key Metrics

```yaml
skill_execution_metrics:
  - skill_usage_count: counter
  - skill_execution_duration: histogram
  - skill_success_rate: gauge
  - skill_error_rate: counter
  - security_violations: counter

security_metrics:
  - approval_request_count: counter
  - approval_response_time: histogram
  - sandbox_creation_count: counter
  - audit_event_count: counter
  - policy_violation_count: counter

performance_metrics:
  - resource_utilization: gauge
  - concurrent_skill_executions: gauge
  - queue_length: gauge
  - throughput_rate: gauge
```

### Alerting Rules

```yaml
critical_alerts:
  - security_violation_rate > 0.01
  - system_skill_approval_failures > 5
  - sandbox_escape_attempts > 0
  - unauthorized_access_attempts > 10

warning_alerts:
  - skill_error_rate > 0.05
  - approval_response_time > 1800  # 30 minutes
  - resource_utilization > 0.85
  - queue_length > 50
```

---

## USAGE GUIDELINES

### For Agent Developers

1. **Skill Selection**: Always use the lowest-risk skill that can accomplish the task
2. **Error Handling**: Implement robust error handling for all tool and system skills
3. **Approval Planning**: Factor approval time into execution planning for system skills
4. **Security First**: Validate all inputs and sanitize all outputs
5. **Tracing**: Include comprehensive tracing for audit and debugging

### For System Administrators

1. **Regular Review**: Review and update skill permissions monthly
2. **Approval Monitoring**: Monitor approval response times and adjust workflows
3. **Security Auditing**: Regularly audit skill usage patterns for anomalies  
4. **Performance Optimization**: Monitor resource usage and optimize constraints
5. **Policy Updates**: Update security policies based on threat landscape changes

### For Security Officers

1. **Risk Assessment**: Regularly assess and update skill risk classifications
2. **Approval Oversight**: Review high-risk skill approval patterns
3. **Incident Response**: Investigate security violations and policy breaches
4. **Compliance**: Ensure skill usage meets regulatory requirements
5. **Training**: Provide security training for agent developers

---

**Document Version**: 1.0  
**Last Updated**: 2025-09-30  
**Next Review**: 2025-10-30  
**Owner**: Primarch Agent Team
