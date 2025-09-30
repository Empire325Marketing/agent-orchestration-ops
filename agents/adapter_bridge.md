# Adapter Bridge Integration (DW-01/DW-03)

## Overview

This document specifies the integration patterns for connecting the Tool Adapter (DW-01) and Speech I/O (DW-03) components with the Primarch orchestrator.

## Routing Configuration

### Tool Adapter Routes

```yaml
# Kong Gateway Routes for Tool Adapter
- name: tool-adapter-execute
  paths: ["/v1/tools/execute"]
  methods: ["POST"]
  service: tool-adapter-service
  plugins:
    - name: rate-limiting
      config:
        minute: 60
        hour: 1000
    - name: request-validator
      config:
        body_schema: |
          {
            "type": "object",
            "required": ["tool_name", "inputs", "context"],
            "properties": {
              "tool_name": {"type": "string"},
              "inputs": {"type": "object"},
              "context": {
                "type": "object",
                "required": ["tenant_id", "session_id"]
              }
            }
          }

- name: tool-adapter-list
  paths: ["/v1/tools"]
  methods: ["GET"]
  service: tool-adapter-service
  
- name: tool-adapter-health
  paths: ["/v1/tools/health"]
  methods: ["GET"]
  service: tool-adapter-service
```

### Speech I/O Routes

```yaml
# ASR (Automatic Speech Recognition)
- name: speech-asr
  paths: ["/v1/speech/asr"]
  methods: ["POST"]
  service: speech-service
  plugins:
    - name: file-size-limiting
      config:
        max_file_size: 25 # MB
    - name: rate-limiting
      config:
        minute: 10
        hour: 100

# TTS (Text-to-Speech)
- name: speech-tts
  paths: ["/v1/speech/tts"]
  methods: ["POST"]
  service: speech-service
  plugins:
    - name: rate-limiting
      config:
        minute: 30
        hour: 500
```

## Orchestrator Integration Snippets

### Tool Execution Flow

```python
# orchestrator/agents/integration.py
from agents.tool_adapter import get_adapter, ToolContext, ToolExecutionStatus

async def execute_agent_tool(agent_id: str, tool_request: dict, session_context: dict):
    """Execute tool through adapter with proper context"""
    
    # Build tool context from session
    context = ToolContext(
        tenant_id=session_context['tenant_id'],
        session_id=session_context['session_id'],
        user_id=session_context.get('user_id'),
        agent_id=agent_id,
        permission_level=session_context.get('permission_level', 'user'),
        max_execution_time=tool_request.get('timeout', 30)
    )
    
    # Execute through adapter
    adapter = get_adapter()
    result = await adapter.execute_tool(
        tool_name=tool_request['tool_name'],
        inputs=tool_request['inputs'],
        context=context
    )
    
    # Handle result based on status
    if result.status == ToolExecutionStatus.SUCCESS:
        return {
            'success': True,
            'data': result.data,
            'execution_time_ms': result.execution_time_ms
        }
    else:
        return {
            'success': False,
            'error': result.error,
            'status': result.status.value,
            'execution_time_ms': result.execution_time_ms
        }
```

### Speech Integration Flow

```python
# orchestrator/agents/speech_integration.py
async def process_speech_input(audio_data: bytes, session_context: dict):
    """Process speech input through ASR"""
    
    asr_context = ToolContext(
        tenant_id=session_context['tenant_id'],
        session_id=session_context['session_id'],
        permission_level='user',
        max_execution_time=60  # ASR can take longer
    )
    
    adapter = get_adapter()
    result = await adapter.execute_tool(
        tool_name='asr_faster_whisper',
        inputs={'audio_data': audio_data, 'language': 'auto'},
        context=asr_context
    )
    
    return result

async def generate_speech_output(text: str, session_context: dict):
    """Generate speech output through TTS"""
    
    tts_context = ToolContext(
        tenant_id=session_context['tenant_id'],
        session_id=session_context['session_id'],
        permission_level='user',
        max_execution_time=30
    )
    
    adapter = get_adapter()
    result = await adapter.execute_tool(
        tool_name='tts_piper',
        inputs={'text': text, 'voice': 'en_US-lessac-medium'},
        context=tts_context
    )
    
    return result
```

## Metrics Naming Convention

### Tool Adapter Metrics

All tool adapter metrics use the prefix `primarch_tool_` and include consistent labels:

```yaml
# Core execution metrics
primarch_tool_executions_total:
  type: counter
  help: "Total tool executions"
  labels: [tool_name, status, tenant_id]

primarch_tool_execution_duration_seconds:
  type: histogram
  help: "Tool execution duration"
  labels: [tool_name, tenant_id]
  buckets: [0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0]

primarch_active_tool_executions:
  type: gauge
  help: "Currently executing tools"
  labels: [tool_name, tenant_id]

# Registry and health metrics
primarch_tool_registry_tools_total:
  type: gauge
  help: "Total tools in registry"

primarch_tool_registry_reload_total:
  type: counter
  help: "Registry reload attempts"
  labels: [status]

primarch_tool_validation_errors_total:
  type: counter
  help: "Tool input validation errors"
  labels: [tool_name, error_type, tenant_id]
```

### Speech I/O Metrics

Speech metrics use the prefix `primarch_speech_`:

```yaml
# ASR metrics
primarch_speech_asr_requests_total:
  type: counter
  help: "Total ASR requests"
  labels: [language, status, tenant_id]

primarch_speech_asr_duration_seconds:
  type: histogram
  help: "ASR processing duration"
  labels: [language, tenant_id]
  buckets: [0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0]

primarch_speech_asr_audio_duration_seconds:
  type: histogram
  help: "Duration of audio processed"
  labels: [language, tenant_id]

# TTS metrics
primarch_speech_tts_requests_total:
  type: counter
  help: "Total TTS requests"
  labels: [voice, status, tenant_id]

primarch_speech_tts_generation_duration_seconds:
  type: histogram
  help: "TTS generation duration"
  labels: [voice, tenant_id]

primarch_speech_tts_output_duration_seconds:
  type: histogram
  help: "Duration of generated audio"
  labels: [voice, tenant_id]
```

## Error Handling Patterns

### Tool Adapter Error Boundaries

```python
# orchestrator/middleware/error_boundaries.py
class ToolAdapterErrorBoundary:
    """Error boundary for tool adapter failures"""
    
    @staticmethod
    async def handle_tool_error(result: ToolResult, fallback_behavior: str = 'graceful'):
        """Handle tool execution errors with fallback strategies"""
        
        if result.status == ToolExecutionStatus.TIMEOUT:
            return {
                'error': 'Tool execution timed out',
                'fallback': 'timeout_recovery',
                'retry_suggested': True
            }
        
        elif result.status == ToolExecutionStatus.PERMISSION_DENIED:
            return {
                'error': 'Insufficient permissions',
                'fallback': 'permission_escalation',
                'retry_suggested': False
            }
        
        elif result.status == ToolExecutionStatus.VALIDATION_ERROR:
            return {
                'error': result.error,
                'fallback': 'input_validation',
                'retry_suggested': False
            }
        
        else:
            return {
                'error': result.error,
                'fallback': 'generic_recovery',
                'retry_suggested': True
            }
```

## Configuration Management

### Environment Variables

```bash
# Tool Adapter Configuration
PRIMARCH_TOOL_REGISTRY_PATH=/srv/primarch/tool_registry.yaml
PRIMARCH_TOOL_MAX_CONCURRENT=50
PRIMARCH_TOOL_DEFAULT_TIMEOUT=30

# Speech I/O Configuration
PRIMARCH_SPEECH_ASR_MODEL_PATH=/srv/primarch/models/faster-whisper-large-v2
PRIMARCH_SPEECH_TTS_MODEL_PATH=/srv/primarch/models/piper-voices
PRIMARCH_SPEECH_MAX_AUDIO_SIZE=25MB
PRIMARCH_SPEECH_CACHE_TTL=3600
```

### Service Dependencies

```yaml
# docker-compose.yml snippet
services:
  tool-adapter:
    depends_on:
      - postgres
      - prometheus
      - vault
    environment:
      - PRIMARCH_TOOL_REGISTRY_PATH=/config/tool_registry.yaml
    volumes:
      - ./tool_registry.yaml:/config/tool_registry.yaml:ro
      - prometheus-metrics:/metrics
      
  speech-service:
    depends_on:
      - tool-adapter
      - file-storage
    environment:
      - PRIMARCH_SPEECH_ASR_MODEL_PATH=/models/faster-whisper
      - PRIMARCH_SPEECH_TTS_MODEL_PATH=/models/piper
    volumes:
      - ai-models:/models:ro
      - temp-storage:/tmp
```

## Health Check Integration

### Orchestrator Health Dependencies

The orchestrator should include tool adapter and speech service health in its overall health check:

```python
async def check_adapter_health():
    """Check tool adapter health"""
    adapter = get_adapter()
    health = adapter.get_tool_health()
    return health['status'] == 'healthy'

async def check_speech_health():
    """Check speech services health"""
    # Check ASR model availability
    asr_available = os.path.exists(os.getenv('PRIMARCH_SPEECH_ASR_MODEL_PATH'))
    # Check TTS model availability  
    tts_available = os.path.exists(os.getenv('PRIMARCH_SPEECH_TTS_MODEL_PATH'))
    
    return asr_available and tts_available
```

This integration ensures the Tool Adapter and Speech I/O components are properly wired into the Primarch orchestrator with full observability and error handling.
