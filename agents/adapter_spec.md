# Agent Adapter Interface (MVP)

## Overview
The Agent Adapter Interface provides a unified abstraction layer for integrating multiple agent frameworks (LangGraph, AutoGen, Pydantic-AI, LlamaIndex) into the Primarch system. This interface ensures consistent behavior, safety controls, and observability across all supported frameworks.

## Core Interface Definition

### Primary Methods

#### `plan(input, context) -> Plan`
```python
@dataclass
class Plan:
    steps: List[PlanStep]
    max_steps: int
    id: str
    metadata: Dict[str, Any]

@dataclass  
class PlanStep:
    action: str
    parameters: Dict[str, Any]
    dependencies: List[str]
    timeout_seconds: int
```

**Purpose**: Generate execution plan from user input and context
**Parameters**:
- `input`: User query or instruction
- `context`: Session context, memory, available tools
**Returns**: Structured plan with steps, dependencies, and metadata

#### `execute(step, tools, context) -> StepResult`
```python
@dataclass
class StepResult:
    status: StepStatus  # SUCCESS, FAILED, RETRY, BLOCKED
    output_json: Dict[str, Any]
    tokens: TokenUsage
    trace_id: str
    error_message: Optional[str]
    next_step_suggestions: List[str]

class StepStatus(Enum):
    SUCCESS = "success"
    FAILED = "failed"
    RETRY = "retry"
    BLOCKED = "blocked"  # waiting for human input
```

**Purpose**: Execute individual step with safety controls and monitoring
**Parameters**:
- `step`: Plan step to execute
- `tools`: Available tool instances with allowlist filtering
- `context`: Execution context with state and memory
**Returns**: Structured result with status, outputs, and telemetry

#### `validate(output_json, schema) -> ValidationResult`
```python
@dataclass
class ValidationResult:
    ok: bool
    errors: List[ValidationError]
    warnings: List[str]
    corrected_output: Optional[Dict[str, Any]]

@dataclass
class ValidationError:
    field: str
    message: str
    code: str
    severity: ValidationSeverity
```

**Purpose**: Validate outputs against expected schemas with correction hints
**Returns**: Validation status with detailed error information and suggestions

## Safety & Limits Configuration

### Limits Enforcement
```python
@dataclass
class ExecutionLimits:
    max_steps: int = 50
    max_tokens: int = 100000
    wall_time_s: int = 300
    max_tool_calls: int = 20
    max_retries: int = 3
    
    # Resource limits
    memory_limit_mb: int = 1024
    cpu_time_limit_s: int = 60
```

**Critical Requirements**:
- MUST enforce hard stops at max_steps (no exceptions)
- MUST respect wall_time_s for total execution timeout
- MUST track and limit token consumption
- MUST prevent infinite loops through step counting and detection

### Security Controls
```python
@dataclass
class SecurityConfig:
    tool_allowlist: List[str]  # Only permitted tools
    tenant_id: str  # Multi-tenant isolation
    sandbox: bool = True  # Default sandboxed execution
    human_approval_required: List[str]  # Actions requiring approval
    sensitive_data_patterns: List[str]  # PII detection patterns
```

**Security Requirements**:
- MUST operate in sandbox by default
- MUST respect tool allowlists (hard enforcement)
- MUST not expose system internals or prompts
- MUST validate tenant isolation

## Hook System

### Event Hooks
```python
class AdapterHooks:
    def on_plan_created(self, plan: Plan, context: ExecutionContext) -> None:
        """Called when plan is generated"""
        pass
    
    def on_step_start(self, step: PlanStep, context: ExecutionContext) -> None:
        """Called before step execution"""
        pass
    
    def on_step_complete(self, step: PlanStep, result: StepResult, context: ExecutionContext) -> None:
        """Called after step completion"""
        pass
    
    def on_retry(self, step: PlanStep, attempt: int, backoff_ms: int) -> None:
        """Called on step retry with exponential backoff"""
        pass
    
    def on_abort(self, reason: str, context: ExecutionContext) -> None:
        """Called when execution is terminated"""
        pass
    
    def on_trace(self, trace_event: TraceEvent, context: ExecutionContext) -> None:
        """Called for distributed tracing events"""
        pass
```

### Retry Policies
```python
@dataclass
class RetryConfig:
    max_attempts: int = 3
    base_delay_ms: int = 1000
    max_delay_ms: int = 30000
    exponential_base: float = 2.0
    jitter: bool = True
    
    # Retry conditions
    retry_on_statuses: List[StepStatus] = field(default_factory=lambda: [StepStatus.RETRY])
    retry_on_errors: List[str] = field(default_factory=list)
```

## Context & State Management

### Execution Context
```python
@dataclass
class ExecutionContext:
    session_id: str
    tenant_id: str
    user_id: str
    trace_id: str
    
    # State management
    persistent_state: Dict[str, Any]
    session_memory: List[Message]
    tool_results_cache: Dict[str, Any]
    
    # Execution tracking
    step_count: int = 0
    token_usage: TokenUsage = field(default_factory=TokenUsage)
    start_time: datetime = field(default_factory=datetime.now)
```

### Memory Management
```python
class MemoryManager:
    def store_message(self, role: str, content: str, metadata: Dict[str, Any]) -> None:
        """Store conversation message with metadata"""
        
    def get_context_window(self, max_tokens: int) -> List[Message]:
        """Retrieve relevant context within token limit"""
        
    def summarize_history(self, target_tokens: int) -> str:
        """Compress old messages to summary"""
        
    def clear_session(self, session_id: str) -> None:
        """Clear session-specific memory"""
```

## Framework-Specific Implementations

### LangGraph Adapter
```python
class LangGraphAdapter(BaseAgentAdapter):
    def plan(self, input: str, context: ExecutionContext) -> Plan:
        # Create graph nodes and edges
        # Map to Plan structure
        # Include state management nodes
        
    def execute(self, step: PlanStep, tools: List[Tool], context: ExecutionContext) -> StepResult:
        # Execute graph node
        # Handle state transitions
        # Capture trace information
        
    def _create_graph(self, plan: Plan) -> Graph:
        # Build LangGraph from plan steps
        # Add safety nodes (validation, limits)
        # Configure checkpointing
```

### AutoGen Adapter  
```python
class AutoGenAdapter(BaseAgentAdapter):
    def plan(self, input: str, context: ExecutionContext) -> Plan:
        # Define agent roles and conversation flow
        # Set termination conditions
        # Configure group chat parameters
        
    def execute(self, step: PlanStep, tools: List[Tool], context: ExecutionContext) -> StepResult:
        # Initialize agents for step
        # Execute conversation round
        # Handle human-in-the-loop
```

## Observability & Monitoring

### Tracing Requirements
```python
@dataclass
class TraceEvent:
    trace_id: str
    span_id: str
    parent_span_id: Optional[str]
    operation: str
    timestamp: datetime
    duration_ms: Optional[int]
    
    # Context
    tags: Dict[str, str]
    logs: List[LogEntry]
    metrics: Dict[str, float]
```

**Critical Requirements**:
- MUST propagate trace_id across all framework calls
- MUST capture step-level spans with timing
- MUST log tool invocations with parameters (sanitized)
- MUST track token usage and costs

### Metrics Collection
```python
# Prometheus-style metrics
agent_step_duration_seconds = Histogram("agent_step_duration_seconds", ["framework", "step_type"])
agent_step_total = Counter("agent_step_total", ["framework", "status"])
agent_tokens_consumed = Counter("agent_tokens_consumed", ["framework", "model"])
agent_active_sessions = Gauge("agent_active_sessions", ["framework"])
```

## Error Handling & Recovery

### Error Classification
```python
class ErrorCategory(Enum):
    VALIDATION_ERROR = "validation"  # Invalid inputs/outputs
    TOOL_ERROR = "tool"  # Tool execution failures
    LIMIT_EXCEEDED = "limit"  # Resource/time limits hit
    FRAMEWORK_ERROR = "framework"  # Internal framework issues
    SECURITY_VIOLATION = "security"  # Safety/security breaches
    
class AdapterError(Exception):
    category: ErrorCategory
    retryable: bool
    user_message: str
    technical_details: Dict[str, Any]
```

### Recovery Strategies
- **Validation Errors**: Retry with corrected schema
- **Tool Errors**: Skip tool or use fallback
- **Limit Exceeded**: Graceful termination with partial results
- **Framework Errors**: Log and switch to fallback adapter
- **Security Violations**: Immediate termination and alert

## Testing & Acceptance Criteria

### Required Tests
```python
class AdapterTestSuite:
    def test_deterministic_outputs(self):
        """Same input -> same schema fields across runs"""
        
    def test_hard_limits(self):
        """max_steps enforcement, no infinite loops"""
        
    def test_trace_propagation(self):
        """trace_id flows through all operations"""
        
    def test_prompt_injection_resistance(self):
        """Security suite -> 0 escapes"""
        
    def test_sandbox_isolation(self):
        """No system access without explicit permissions"""
        
    def test_graceful_degradation(self):
        """Partial results when limits hit"""
```

### Performance Benchmarks
- **Plan Generation**: < 2 seconds for typical workflows
- **Step Execution**: < 30 seconds per step (configurable)
- **Memory Usage**: < 512MB per active session
- **Concurrent Sessions**: Support 100+ simultaneous executions

## Deployment & Configuration

### Configuration Schema
```yaml
# /srv/primarch/config/agent_adapters.yaml
adapters:
  langgraph:
    enabled: true
    default_limits:
      max_steps: 50
      wall_time_s: 300
    safety:
      sandbox: true
      tool_allowlist: ["web_search", "file_read", "calculator"]
    
  autogen:
    enabled: true
    human_in_loop: true
    conversation_limits:
      max_rounds: 20
      
monitoring:
  tracing_enabled: true
  metrics_port: 9090
  log_level: INFO
```

### Health Checks
```python
def health_check() -> Dict[str, Any]:
    return {
        "status": "healthy",
        "adapters": {
            adapter.name: adapter.is_available() 
            for adapter in registered_adapters
        },
        "limits_enforced": True,
        "sandbox_available": check_sandbox_health(),
        "trace_collector": check_tracing_health()
    }
```

## Migration & Compatibility

### Version Compatibility
- Support adapter versioning for gradual rollouts
- Backward compatibility for existing workflows
- Schema evolution with migration helpers

### Framework Updates
- Adapters MUST handle framework version changes gracefully
- Deprecation warnings for unsupported features
- Automatic fallbacks when possible

---

**Specification Version**: 1.0  
**Target Frameworks**: LangGraph 0.2+, AutoGen 0.3+, Pydantic-AI 0.1+, LlamaIndex 0.11+  
**Status**: Draft for Review  
**Next Review**: October 15, 2025
