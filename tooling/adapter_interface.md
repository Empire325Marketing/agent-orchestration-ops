# Primarch Tool Adapter Interface Specification

## Overview

The Primarch Tool Adapter provides a unified interface for tool invocation across the multi-agent system, built primarily on Haystack's component architecture with Pydantic-AI integration for high-validation scenarios.

## Core Architecture

### Base Adapter Interface

```python
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List
from pydantic import BaseModel, Field
from enum import Enum
import asyncio
from datetime import datetime

class ToolResult(BaseModel):
    """Standardized tool execution result"""
    success: bool
    data: Any = None
    error: Optional[str] = None
    execution_time_ms: int
    metadata: Dict[str, Any] = Field(default_factory=dict)
    trace_id: str

class ToolRequest(BaseModel):
    """Standardized tool invocation request"""
    tool_name: str
    parameters: Dict[str, Any]
    context: Optional[Dict[str, Any]] = None
    timeout_ms: int = 30000
    retry_count: int = 3
    trace_id: str
    
class ToolStatus(Enum):
    IDLE = "idle"
    RUNNING = "running" 
    ERROR = "error"
    DISABLED = "disabled"

class BaseTool(ABC):
    """Abstract base class for all Primarch tools"""
    
    def __init__(self, name: str, config: Dict[str, Any]):
        self.name = name
        self.config = config
        self.status = ToolStatus.IDLE
        self.call_count = 0
        self.error_count = 0
        
    @abstractmethod
    async def invoke(self, request: ToolRequest) -> ToolResult:
        """Execute the tool with given parameters"""
        pass
        
    @abstractmethod
    def get_schema(self) -> Dict[str, Any]:
        """Return OpenAPI-compatible schema for the tool"""
        pass
        
    def get_health(self) -> Dict[str, Any]:
        """Return tool health metrics"""
        return {
            "name": self.name,
            "status": self.status.value,
            "call_count": self.call_count,
            "error_count": self.error_count,
            "error_rate": self.error_count / max(1, self.call_count)
        }
```

### Primary Adapter: Haystack-Based

```python
from haystack import Pipeline, Document
from haystack.components.builders import DynamicChatPromptBuilder
from haystack.components.generators import OpenAIGenerator
from haystack.core.component import Component
from haystack.core.component.types import Variadic
import logging

class HaystackToolComponent(Component):
    """Haystack component wrapper for Primarch tools"""
    
    def __init__(self, tool: BaseTool):
        self.tool = tool
        
    @component.output_types(result=ToolResult)
    def run(self, request: ToolRequest) -> Dict[str, Any]:
        """Execute tool within Haystack pipeline"""
        try:
            loop = asyncio.get_event_loop()
            result = loop.run_until_complete(self.tool.invoke(request))
            return {"result": result}
        except Exception as e:
            return {"result": ToolResult(
                success=False,
                error=str(e),
                execution_time_ms=0,
                trace_id=request.trace_id
            )}

class PrimarchAdapter:
    """Primary tool adapter using Haystack pipelines"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.pipeline = Pipeline()
        self.tools: Dict[str, BaseTool] = {}
        self.logger = logging.getLogger(__name__)
        
    def register_tool(self, tool: BaseTool) -> None:
        """Register a tool with the adapter"""
        self.tools[tool.name] = tool
        component = HaystackToolComponent(tool)
        self.pipeline.add_component(f"tool_{tool.name}", component)
        self.logger.info(f"Registered tool: {tool.name}")
        
    async def invoke_tool(self, request: ToolRequest) -> ToolResult:
        """Invoke a tool through the pipeline"""
        if request.tool_name not in self.tools:
            return ToolResult(
                success=False,
                error=f"Tool not found: {request.tool_name}",
                execution_time_ms=0,
                trace_id=request.trace_id
            )
            
        start_time = datetime.now()
        
        try:
            # Execute with retry logic
            for attempt in range(request.retry_count):
                try:
                    result = await self._execute_with_timeout(request)
                    execution_time = (datetime.now() - start_time).microseconds // 1000
                    result.execution_time_ms = execution_time
                    return result
                except Exception as e:
                    if attempt == request.retry_count - 1:
                        raise
                    await asyncio.sleep(2 ** attempt)  # Exponential backoff
                    
        except Exception as e:
            execution_time = (datetime.now() - start_time).microseconds // 1000
            self.logger.error(f"Tool {request.tool_name} failed: {str(e)}")
            return ToolResult(
                success=False,
                error=str(e),
                execution_time_ms=execution_time,
                trace_id=request.trace_id
            )
    
    async def _execute_with_timeout(self, request: ToolRequest) -> ToolResult:
        """Execute tool with timeout protection"""
        return await asyncio.wait_for(
            self.tools[request.tool_name].invoke(request),
            timeout=request.timeout_ms / 1000
        )
        
    def get_available_tools(self) -> List[str]:
        """Return list of available tool names"""
        return list(self.tools.keys())
        
    def get_tool_schema(self, tool_name: str) -> Optional[Dict[str, Any]]:
        """Get schema for specific tool"""
        if tool_name in self.tools:
            return self.tools[tool_name].get_schema()
        return None
        
    def get_system_health(self) -> Dict[str, Any]:
        """Return system health metrics"""
        return {
            "adapter_type": "haystack",
            "total_tools": len(self.tools),
            "tools": [tool.get_health() for tool in self.tools.values()]
        }
```

### Secondary Adapter: Pydantic-AI Integration

```python
from pydantic_ai import Agent, ModelRetry
from pydantic import BaseModel, ValidationError

class ValidatedToolRequest(BaseModel):
    """Pydantic-validated tool request for high-safety scenarios"""
    tool_name: str
    parameters: Dict[str, Any]
    validation_schema: Optional[Dict[str, Any]] = None
    
class PydanticToolAdapter:
    """High-validation adapter using Pydantic-AI"""
    
    def __init__(self, model_name: str = "openai:gpt-4"):
        self.agent = Agent(model_name)
        self.validation_tools: Dict[str, BaseTool] = {}
        
    def register_validation_tool(self, tool: BaseTool) -> None:
        """Register tool for high-validation scenarios"""
        self.validation_tools[tool.name] = tool
        
        @self.agent.tool_plain
        async def validated_invoke(request: ValidatedToolRequest) -> ToolResult:
            """Invoke tool with Pydantic validation"""
            try:
                # Validate input against schema if provided
                if request.validation_schema:
                    # Additional validation logic here
                    pass
                    
                tool_request = ToolRequest(
                    tool_name=request.tool_name,
                    parameters=request.parameters,
                    trace_id=f"pydantic_{datetime.now().isoformat()}"
                )
                
                return await tool.invoke(tool_request)
                
            except ValidationError as e:
                return ToolResult(
                    success=False,
                    error=f"Validation failed: {str(e)}",
                    execution_time_ms=0,
                    trace_id=tool_request.trace_id
                )
                
    async def invoke_with_validation(self, request: str, context: Dict[str, Any]) -> Any:
        """Invoke agent with validation"""
        return await self.agent.run(request, deps=context)
```

### Hybrid Adapter Manager

```python
class AdapterManager:
    """Manages both Haystack and Pydantic-AI adapters"""
    
    def __init__(self, config: Dict[str, Any]):
        self.haystack_adapter = PrimarchAdapter(config.get("haystack", {}))
        self.pydantic_adapter = PydanticToolAdapter(
            config.get("pydantic_model", "openai:gpt-4")
        )
        self.validation_threshold = config.get("validation_threshold", 0.8)
        
    async def invoke_tool(self, request: ToolRequest, require_validation: bool = False) -> ToolResult:
        """Route to appropriate adapter based on requirements"""
        
        if require_validation or self._needs_high_validation(request):
            # Use Pydantic-AI for high-validation scenarios
            validated_request = ValidatedToolRequest(
                tool_name=request.tool_name,
                parameters=request.parameters
            )
            return await self.pydantic_adapter.invoke_with_validation(
                str(validated_request), 
                request.context or {}
            )
        else:
            # Use Haystack for standard scenarios  
            return await self.haystack_adapter.invoke_tool(request)
            
    def _needs_high_validation(self, request: ToolRequest) -> bool:
        """Determine if request needs high validation"""
        # Check for PII, financial data, or other sensitive parameters
        sensitive_patterns = ["ssn", "credit_card", "password", "api_key"]
        
        for param_value in str(request.parameters).lower():
            if any(pattern in param_value for pattern in sensitive_patterns):
                return True
                
        return False
        
    def register_tool(self, tool: BaseTool, validation_required: bool = False) -> None:
        """Register tool with appropriate adapter(s)"""
        self.haystack_adapter.register_tool(tool)
        
        if validation_required:
            self.pydantic_adapter.register_validation_tool(tool)
```

## Configuration Schema

```yaml
# adapter_config.yaml
adapter:
  type: "hybrid"  # haystack, pydantic, hybrid
  
haystack:
  pipeline_cache_size: 1000
  async_timeout_ms: 30000
  retry_count: 3
  
pydantic:
  model: "openai:gpt-4"
  validation_threshold: 0.8
  strict_mode: true
  
monitoring:
  enable_tracing: true
  metrics_endpoint: "/metrics"
  health_check_interval: 30
  
security:
  enable_input_validation: true
  pii_detection: true
  rate_limiting:
    requests_per_minute: 1000
    burst_size: 100
```

## Error Handling & Resilience

```python
class AdapterError(Exception):
    """Base exception for adapter errors"""
    pass

class ToolNotFoundError(AdapterError):
    """Tool not registered with adapter"""
    pass

class ValidationError(AdapterError):
    """Input/output validation failed"""
    pass

class TimeoutError(AdapterError):
    """Tool execution timed out"""
    pass

# Circuit breaker pattern for tool reliability
from circuit_breaker import CircuitBreaker

class ResilientTool(BaseTool):
    """Tool wrapper with circuit breaker protection"""
    
    def __init__(self, tool: BaseTool, failure_threshold: int = 5):
        super().__init__(tool.name, tool.config)
        self.tool = tool
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=failure_threshold,
            timeout_duration=60,
            expected_exception=Exception
        )
        
    @circuit_breaker
    async def invoke(self, request: ToolRequest) -> ToolResult:
        """Invoke with circuit breaker protection"""
        return await self.tool.invoke(request)
```

## Monitoring & Observability

```python
from prometheus_client import Counter, Histogram, Gauge
import opentelemetry
from opentelemetry import trace

# Metrics
tool_invocations = Counter('primarch_tool_invocations_total', 
                          'Total tool invocations', ['tool_name', 'status'])
tool_duration = Histogram('primarch_tool_duration_seconds',
                         'Tool execution duration', ['tool_name'])
active_tools = Gauge('primarch_active_tools', 'Number of active tools')

# Tracing
tracer = trace.get_tracer(__name__)

class TracedAdapter(PrimarchAdapter):
    """Adapter with full observability"""
    
    async def invoke_tool(self, request: ToolRequest) -> ToolResult:
        with tracer.start_as_current_span("tool_invocation") as span:
            span.set_attributes({
                "tool.name": request.tool_name,
                "tool.trace_id": request.trace_id
            })
            
            start_time = time.time()
            result = await super().invoke_tool(request)
            duration = time.time() - start_time
            
            # Record metrics
            tool_invocations.labels(
                tool_name=request.tool_name,
                status="success" if result.success else "error"
            ).inc()
            
            tool_duration.labels(tool_name=request.tool_name).observe(duration)
            
            span.set_attributes({
                "tool.success": result.success,
                "tool.duration_ms": result.execution_time_ms
            })
            
            return result
```

## Usage Examples

```python
# Initialize adapter
config = {
    "haystack": {"async_timeout_ms": 30000},
    "pydantic_model": "openai:gpt-4"
}

adapter = AdapterManager(config)

# Register tools
jira_tool = JiraTool("jira_connector", jira_config)
slack_tool = SlackTool("slack_connector", slack_config)

adapter.register_tool(jira_tool, validation_required=False)
adapter.register_tool(slack_tool, validation_required=True)  # High validation for messaging

# Invoke tool
request = ToolRequest(
    tool_name="jira_connector",
    parameters={"action": "create_issue", "project": "PRIM", "summary": "Test issue"},
    trace_id="req_12345"
)

result = await adapter.invoke_tool(request)
print(f"Success: {result.success}, Data: {result.data}")
```

This interface provides the foundation for reliable, scalable tool orchestration across the Primarch multi-agent system.
