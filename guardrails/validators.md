# Primarch DW-05: Guardrails Validation Patterns and Schemas

**Document ID:** PR-DW05-VAL-001
**Version:** 1.0.0
**Last Updated:** 2025-09-30
**Target:** ≤1% structured output error rate after auto-repair

## Overview

This document provides comprehensive validation patterns, schemas, and implementation guidance for the Primarch DW-05 Guardrails Hardening system. These patterns ensure reliable structured output generation while maintaining strict security and safety standards.

## 1. JSON Schema Validation Patterns

### 1.1. Core Schema Definitions

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "LLMResponse",
  "type": "object",
  "properties": {
    "content": {
      "type": "string",
      "minLength": 1,
      "maxLength": 32768,
      "pattern": "^[\\s\\S]*$",
      "description": "Main response content"
    },
    "confidence": {
      "type": "number",
      "minimum": 0.0,
      "maximum": 1.0,
      "description": "Model confidence score"
    },
    "citations": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "source": {"type": "string", "format": "uri"},
          "excerpt": {"type": "string", "maxLength": 500},
          "relevance_score": {"type": "number", "minimum": 0.0, "maximum": 1.0}
        },
        "required": ["source", "excerpt"],
        "additionalProperties": false
      },
      "maxItems": 10
    },
    "safety_flags": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["toxicity", "bias", "pii", "secrets", "prompt_injection", "jailbreak"]
      },
      "uniqueItems": true
    },
    "metadata": {
      "type": "object",
      "properties": {
        "model": {"type": "string"},
        "timestamp": {"type": "string", "format": "date-time"},
        "request_id": {"type": "string", "pattern": "^[a-f0-9-]{36}$"}
      },
      "required": ["model", "timestamp", "request_id"],
      "additionalProperties": false
    }
  },
  "required": ["content", "confidence", "metadata"],
  "additionalProperties": false
}
```

### 1.2. Tool Execution Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ToolExecution",
  "type": "object",
  "properties": {
    "tool_name": {
      "type": "string",
      "enum": ["web_search", "code_execution", "file_read", "database_query"],
      "description": "Allowed tool identifier"
    },
    "parameters": {
      "type": "object",
      "description": "Tool-specific parameters"
    },
    "safety_check": {
      "type": "boolean",
      "description": "Pre-execution safety validation passed"
    },
    "execution_context": {
      "type": "string",
      "enum": ["sandbox", "restricted", "privileged"],
      "default": "sandbox"
    }
  },
  "required": ["tool_name", "parameters", "safety_check"],
  "additionalProperties": false,
  "if": {
    "properties": {"tool_name": {"const": "code_execution"}}
  },
  "then": {
    "properties": {
      "parameters": {
        "type": "object",
        "properties": {
          "language": {"type": "string", "enum": ["python", "javascript", "bash"]},
          "code": {"type": "string", "maxLength": 10000},
          "timeout": {"type": "integer", "minimum": 1, "maximum": 300}
        },
        "required": ["language", "code"],
        "additionalProperties": false
      }
    }
  }
}
```

## 2. Pydantic Model Examples

### 2.1. Basic Response Model with Validation

```python
from typing import List, Optional, Literal
from pydantic import BaseModel, Field, validator, root_validator
from datetime import datetime
import uuid
import re

class Citation(BaseModel):
    source: str = Field(..., description="Source URL or identifier")
    excerpt: str = Field(..., max_length=500, description="Relevant text excerpt")
    relevance_score: float = Field(default=0.0, ge=0.0, le=1.0)
    
    @validator('source')
    def validate_source(cls, v):
        if not (v.startswith('http') or v.startswith('file:')):
            raise ValueError('Source must be a valid URL or file path')
        return v
    
    @validator('excerpt')
    def validate_excerpt_not_empty(cls, v):
        if not v.strip():
            raise ValueError('Excerpt cannot be empty')
        return v.strip()

class SafetyFlags(BaseModel):
    toxicity: bool = False
    bias: bool = False
    pii: bool = False
    secrets: bool = False
    prompt_injection: bool = False
    jailbreak: bool = False
    
    def has_critical_flags(self) -> bool:
        return any([self.secrets, self.prompt_injection, self.jailbreak])
    
    def get_active_flags(self) -> List[str]:
        return [k for k, v in self.dict().items() if v]

class ResponseMetadata(BaseModel):
    model: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    request_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    processing_time_ms: Optional[float] = None
    
    @validator('model')
    def validate_model_name(cls, v):
        allowed_models = ['gpt-4', 'claude-3', 'llama-3', 'primarch-local']
        if v not in allowed_models:
            raise ValueError(f'Model must be one of: {allowed_models}')
        return v

class LLMResponse(BaseModel):
    content: str = Field(..., min_length=1, max_length=32768)
    confidence: float = Field(..., ge=0.0, le=1.0)
    citations: List[Citation] = Field(default_factory=list, max_items=10)
    safety_flags: SafetyFlags = Field(default_factory=SafetyFlags)
    metadata: ResponseMetadata = Field(default_factory=ResponseMetadata)
    
    @validator('content')
    def validate_content_safety(cls, v):
        # Basic content validation
        if any(pattern in v.lower() for pattern in ['<script>', 'javascript:', 'data:text/html']):
            raise ValueError('Content contains potentially malicious code')
        return v
    
    @root_validator
    def validate_response_consistency(cls, values):
        content = values.get('content', '')
        citations = values.get('citations', [])
        
        # Ensure citations are grounded in content
        for citation in citations:
            if citation.excerpt not in content:
                raise ValueError(f'Citation excerpt not found in content: {citation.excerpt[:50]}...')
        
        return values
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
```

### 2.2. Tool Execution Model with Security Constraints

```python
class ToolParameter(BaseModel):
    name: str
    value: str
    data_type: Literal['string', 'integer', 'boolean', 'array', 'object']
    
    @validator('value')
    def validate_no_injection(cls, v):
        # Prevent common injection patterns
        injection_patterns = [
            r';\s*drop\s+table',
            r'<script[^>]*>',
            r'javascript:',
            r'eval\s*\(',
            r'exec\s*\(',
            r'\${.*}',  # Template injection
            r'{{.*}}',  # Template injection
        ]
        
        for pattern in injection_patterns:
            if re.search(pattern, v, re.IGNORECASE):
                raise ValueError(f'Parameter value contains forbidden pattern: {pattern}')
        return v

class ToolExecution(BaseModel):
    tool_name: Literal['web_search', 'code_execution', 'file_read', 'database_query']
    parameters: List[ToolParameter]
    safety_check: bool = False
    execution_context: Literal['sandbox', 'restricted', 'privileged'] = 'sandbox'
    max_execution_time: int = Field(default=30, ge=1, le=300)
    
    @validator('parameters')
    def validate_parameter_count(cls, v, values):
        tool_name = values.get('tool_name')
        max_params = {
            'web_search': 5,
            'code_execution': 3,
            'file_read': 2,
            'database_query': 10
        }
        
        if len(v) > max_params.get(tool_name, 5):
            raise ValueError(f'Too many parameters for {tool_name}')
        return v
    
    @root_validator
    def validate_execution_context(cls, values):
        tool_name = values.get('tool_name')
        execution_context = values.get('execution_context')
        
        # Enforce context restrictions
        restricted_tools = {
            'code_execution': ['sandbox', 'restricted'],
            'database_query': ['restricted', 'privileged'],
            'file_read': ['sandbox', 'restricted', 'privileged'],
            'web_search': ['sandbox', 'restricted', 'privileged']
        }
        
        allowed_contexts = restricted_tools.get(tool_name, ['sandbox'])
        if execution_context not in allowed_contexts:
            raise ValueError(f'{tool_name} not allowed in {execution_context} context')
        
        return values
```

## 3. Input Sanitization and Validation Rules

### 3.1. Comprehensive Input Sanitizer

```python
import html
import re
from typing import Dict, List, Tuple
from urllib.parse import urlparse

class InputSanitizer:
    def __init__(self):
        self.injection_patterns = [
            # SQL injection patterns
            (r"(\bUNION\b|\bSELECT\b|\bINSERT\b|\bDELETE\b|\bUPDATE\b|\bDROP\b)", "SQL_INJECTION"),
            
            # XSS patterns
            (r"<script[^>]*>.*?</script>", "XSS_SCRIPT"),
            (r"javascript:", "XSS_JAVASCRIPT"),
            (r"on\w+\s*=", "XSS_EVENT_HANDLER"),
            
            # Command injection
            (r"[;&|`$(){}]", "COMMAND_INJECTION"),
            (r"(wget|curl|nc|netcat|bash|sh|cmd|powershell)", "COMMAND_EXECUTION"),
            
            # Prompt injection patterns
            (r"ignore\s+all\s+previous\s+instructions", "PROMPT_INJECTION"),
            (r"act\s+as\s+(dan|jailbreak|unrestricted)", "JAILBREAK_ATTEMPT"),
            (r"system\s*[:]\s*", "SYSTEM_PROMPT_OVERRIDE"),
            
            # Template injection
            (r"\{\{.*\}\}", "TEMPLATE_INJECTION"),
            (r"\$\{.*\}", "TEMPLATE_INJECTION"),
            
            # Path traversal
            (r"\.\.[\\/]", "PATH_TRAVERSAL"),
            (r"[\\/]etc[\\/]passwd", "PATH_TRAVERSAL"),
        ]
        
        self.secrets_patterns = [
            (r"[A-Za-z0-9+/]{40,}", "POTENTIAL_TOKEN"),
            (r"AIza[0-9A-Za-z_-]{35}", "GOOGLE_API_KEY"),
            (r"sk-[A-Za-z0-9]{48}", "OPENAI_API_KEY"),
            (r"xox[baprs]-[A-Za-z0-9-]{10,48}", "SLACK_TOKEN"),
            (r"ghp_[A-Za-z0-9]{36}", "GITHUB_TOKEN"),
            (r"AKIA[0-9A-Z]{16}", "AWS_ACCESS_KEY"),
        ]
        
        self.pii_patterns = [
            (r"\b\d{3}-\d{2}-\d{4}\b", "SSN"),
            (r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b", "EMAIL"),
            (r"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b", "CREDIT_CARD"),
            (r"\b(?:\+1[-.\s]?)?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b", "PHONE"),
        ]
    
    def sanitize_input(self, text: str) -> Tuple[str, List[Dict]]:
        """Sanitize input text and return cleaned text with detected threats"""
        threats = []
        cleaned_text = text
        
        # HTML escape first
        cleaned_text = html.escape(cleaned_text)
        
        # Check for injection patterns
        for pattern, threat_type in self.injection_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE | re.MULTILINE)
            for match in matches:
                threats.append({
                    'type': threat_type,
                    'pattern': pattern,
                    'match': match.group(0),
                    'position': match.span(),
                    'severity': 'HIGH'
                })
        
        # Check for secrets
        for pattern, secret_type in self.secrets_patterns:
            matches = re.finditer(pattern, text)
            for match in matches:
                threats.append({
                    'type': secret_type,
                    'pattern': pattern,
                    'match': '[REDACTED]',  # Don't log actual secret
                    'position': match.span(),
                    'severity': 'CRITICAL'
                })
                # Redact from cleaned text
                cleaned_text = cleaned_text.replace(match.group(0), '[REDACTED_SECRET]')
        
        # Check for PII
        for pattern, pii_type in self.pii_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                threats.append({
                    'type': pii_type,
                    'pattern': pattern,
                    'match': '[REDACTED]',  # Don't log actual PII
                    'position': match.span(),
                    'severity': 'HIGH'
                })
                # Redact from cleaned text
                cleaned_text = cleaned_text.replace(match.group(0), f'[REDACTED_{pii_type}]')
        
        return cleaned_text, threats
    
    def validate_url(self, url: str) -> bool:
        """Validate URL is safe for access"""
        try:
            parsed = urlparse(url)
            
            # Only allow HTTP/HTTPS
            if parsed.scheme not in ['http', 'https']:
                return False
            
            # Block internal networks
            blocked_domains = [
                'localhost', '127.0.0.1', '0.0.0.0',
                '10.', '172.16.', '192.168.',
                'metadata.google.internal',
                '169.254.169.254'  # AWS metadata
            ]
            
            if any(blocked in parsed.netloc.lower() for blocked in blocked_domains):
                return False
            
            return True
        except Exception:
            return False
```

### 3.2. Context-Aware Validation

```python
class ContextValidator:
    def __init__(self):
        self.context_rules = {
            'user_input': {
                'max_length': 8192,
                'allowed_formats': ['text', 'markdown'],
                'forbidden_patterns': ['system:', 'assistant:', 'human:'],
                'severity': 'HIGH'
            },
            'system_prompt': {
                'max_length': 2048,
                'allowed_formats': ['text'],
                'required_patterns': ['You are', 'Your role'],
                'severity': 'CRITICAL'
            },
            'tool_output': {
                'max_length': 32768,
                'allowed_formats': ['text', 'json', 'xml'],
                'forbidden_patterns': ['<script>', 'javascript:'],
                'severity': 'MEDIUM'
            }
        }
    
    def validate_context(self, text: str, context_type: str) -> Dict:
        """Validate text within specific context"""
        if context_type not in self.context_rules:
            raise ValueError(f"Unknown context type: {context_type}")
        
        rules = self.context_rules[context_type]
        violations = []
        
        # Length validation
        if len(text) > rules['max_length']:
            violations.append({
                'rule': 'max_length',
                'message': f"Text exceeds maximum length of {rules['max_length']}",
                'severity': rules['severity']
            })
        
        # Pattern validation
        if 'forbidden_patterns' in rules:
            for pattern in rules['forbidden_patterns']:
                if pattern.lower() in text.lower():
                    violations.append({
                        'rule': 'forbidden_pattern',
                        'pattern': pattern,
                        'message': f"Forbidden pattern detected: {pattern}",
                        'severity': rules['severity']
                    })
        
        if 'required_patterns' in rules:
            for pattern in rules['required_patterns']:
                if pattern.lower() not in text.lower():
                    violations.append({
                        'rule': 'required_pattern',
                        'pattern': pattern,
                        'message': f"Required pattern missing: {pattern}",
                        'severity': rules['severity']
                    })
        
        return {
            'valid': len(violations) == 0,
            'violations': violations,
            'context_type': context_type
        }
```

## 4. Auto-Repair Mechanisms

### 4.1. Intelligent Output Repair

```python
import json
from typing import Any, Dict, Optional, Union
from pydantic import ValidationError

class OutputRepairer:
    def __init__(self, max_retries: int = 3):
        self.max_retries = max_retries
        self.common_fixes = {
            'json_syntax': self._fix_json_syntax,
            'missing_fields': self._add_missing_fields,
            'invalid_types': self._fix_type_errors,
            'schema_violations': self._fix_schema_violations
        }
    
    def auto_repair(self, raw_output: str, target_model: BaseModel, 
                   validation_error: ValidationError) -> Optional[Dict[str, Any]]:
        """Attempt to automatically repair malformed output"""
        
        for attempt in range(self.max_retries):
            try:
                # Try to parse as JSON first
                if raw_output.strip().startswith('{'):
                    data = json.loads(raw_output)
                else:
                    # Try to extract JSON from text
                    data = self._extract_json_from_text(raw_output)
                
                # Apply targeted fixes based on validation errors
                for error in validation_error.errors():
                    error_type = error['type']
                    field_path = '.'.join(str(x) for x in error['loc'])
                    
                    if error_type in ['missing', 'value_error.missing']:
                        data = self._add_missing_fields(data, field_path, target_model)
                    elif error_type in ['type_error', 'value_error.number']:
                        data = self._fix_type_errors(data, field_path, error)
                    elif error_type == 'value_error.const':
                        data = self._fix_enum_values(data, field_path, error)
                
                # Validate the repaired data
                return target_model.parse_obj(data).dict()
                
            except Exception as e:
                if attempt == self.max_retries - 1:
                    break
                # Try different repair strategies
                raw_output = self._apply_generic_repairs(raw_output)
        
        return None
    
    def _extract_json_from_text(self, text: str) -> Dict[str, Any]:
        """Extract JSON object from text that may contain other content"""
        # Look for JSON-like structures
        start_idx = text.find('{')
        if start_idx == -1:
            raise ValueError("No JSON structure found")
        
        # Find matching closing brace
        brace_count = 0
        for i, char in enumerate(text[start_idx:], start_idx):
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if brace_count == 0:
                    json_str = text[start_idx:i+1]
                    return json.loads(json_str)
        
        raise ValueError("No complete JSON structure found")
    
    def _fix_json_syntax(self, text: str) -> str:
        """Fix common JSON syntax errors"""
        # Remove trailing commas
        text = re.sub(r',(\s*[}\]])', r'\1', text)
        
        # Fix unquoted keys
        text = re.sub(r'(\w+):', r'"\1":', text)
        
        # Fix single quotes to double quotes
        text = re.sub(r"'([^']*)'", r'"\1"', text)
        
        return text
    
    def _add_missing_fields(self, data: Dict[str, Any], field_path: str, 
                           target_model: BaseModel) -> Dict[str, Any]:
        """Add missing required fields with appropriate defaults"""
        field_schema = self._get_field_schema(target_model, field_path)
        
        if field_path not in data:
            if field_schema.get('type') == 'string':
                data[field_path] = ""
            elif field_schema.get('type') == 'integer':
                data[field_path] = 0
            elif field_schema.get('type') == 'number':
                data[field_path] = 0.0
            elif field_schema.get('type') == 'boolean':
                data[field_path] = False
            elif field_schema.get('type') == 'array':
                data[field_path] = []
            elif field_schema.get('type') == 'object':
                data[field_path] = {}
        
        return data
    
    def _fix_type_errors(self, data: Dict[str, Any], field_path: str, 
                        error: Dict[str, Any]) -> Dict[str, Any]:
        """Fix type conversion errors"""
        current_value = data.get(field_path)
        
        if error['type'] == 'type_error.integer':
            try:
                data[field_path] = int(float(str(current_value)))
            except (ValueError, TypeError):
                data[field_path] = 0
        
        elif error['type'] == 'type_error.float':
            try:
                data[field_path] = float(str(current_value))
            except (ValueError, TypeError):
                data[field_path] = 0.0
        
        elif error['type'] == 'type_error.bool':
            if isinstance(current_value, str):
                data[field_path] = current_value.lower() in ['true', '1', 'yes', 'on']
            else:
                data[field_path] = bool(current_value)
        
        return data
    
    def _fix_enum_values(self, data: Dict[str, Any], field_path: str, 
                        error: Dict[str, Any]) -> Dict[str, Any]:
        """Fix enum constraint violations"""
        permitted = error.get('ctx', {}).get('permitted', [])
        current_value = str(data.get(field_path, '')).lower()
        
        # Try to find a close match
        for option in permitted:
            if current_value in str(option).lower() or str(option).lower() in current_value:
                data[field_path] = option
                break
        else:
            # Use first permitted value as fallback
            if permitted:
                data[field_path] = permitted[0]
        
        return data
    
    def _get_field_schema(self, model: BaseModel, field_path: str) -> Dict[str, Any]:
        """Get schema information for a specific field"""
        schema = model.schema()
        field_name = field_path.split('.')[0]
        return schema.get('properties', {}).get(field_name, {})
    
    def _apply_generic_repairs(self, text: str) -> str:
        """Apply generic text repairs"""
        # Remove non-printable characters
        text = ''.join(char for char in text if char.isprintable() or char.isspace())
        
        # Normalize whitespace
        text = re.sub(r'\s+', ' ', text).strip()
        
        # Try to wrap in JSON if it looks like key-value pairs
        if ':' in text and not text.strip().startswith('{'):
            text = '{' + text + '}'
        
        return text
```

## 5. Error Handling and Fallback Strategies

### 5.1. Hierarchical Error Recovery

```python
from enum import Enum
from typing import Callable, Dict, List, Optional, Any
import logging

class ErrorSeverity(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class FallbackStrategy(Enum):
    RETRY = "retry"
    DEFAULT_VALUE = "default_value"
    ALTERNATIVE_MODEL = "alternative_model"
    HUMAN_ESCALATION = "human_escalation"
    FAIL_SAFE = "fail_safe"

class GuardrailsErrorHandler:
    def __init__(self):
        self.fallback_strategies = {
            ErrorSeverity.LOW: [FallbackStrategy.RETRY, FallbackStrategy.DEFAULT_VALUE],
            ErrorSeverity.MEDIUM: [FallbackStrategy.RETRY, FallbackStrategy.ALTERNATIVE_MODEL, FallbackStrategy.DEFAULT_VALUE],
            ErrorSeverity.HIGH: [FallbackStrategy.ALTERNATIVE_MODEL, FallbackStrategy.HUMAN_ESCALATION],
            ErrorSeverity.CRITICAL: [FallbackStrategy.FAIL_SAFE, FallbackStrategy.HUMAN_ESCALATION]
        }
        
        self.default_values = {
            'content': "I apologize, but I cannot provide a response due to safety constraints.",
            'confidence': 0.0,
            'safety_flags': SafetyFlags(),
            'citations': [],
        }
        
        self.alternative_models = [
            'gpt-3.5-turbo',
            'claude-3-haiku',
            'llama-3-8b'
        ]
    
    def handle_error(self, error: Exception, context: Dict[str, Any], 
                    severity: ErrorSeverity) -> Optional[Any]:
        """Handle errors using appropriate fallback strategy"""
        
        strategies = self.fallback_strategies.get(severity, [FallbackStrategy.FAIL_SAFE])
        
        for strategy in strategies:
            try:
                if strategy == FallbackStrategy.RETRY:
                    return self._retry_with_correction(error, context)
                
                elif strategy == FallbackStrategy.DEFAULT_VALUE:
                    return self._use_default_value(error, context)
                
                elif strategy == FallbackStrategy.ALTERNATIVE_MODEL:
                    return self._try_alternative_model(error, context)
                
                elif strategy == FallbackStrategy.HUMAN_ESCALATION:
                    return self._escalate_to_human(error, context)
                
                elif strategy == FallbackStrategy.FAIL_SAFE:
                    return self._fail_safe_response(error, context)
                    
            except Exception as fallback_error:
                logging.warning(f"Fallback strategy {strategy} failed: {fallback_error}")
                continue
        
        # Ultimate fallback
        return self._fail_safe_response(error, context)
    
    def _retry_with_correction(self, error: Exception, context: Dict[str, Any]) -> Any:
        """Retry operation with error correction"""
        max_retries = context.get('max_retries', 3)
        current_retry = context.get('current_retry', 0)
        
        if current_retry >= max_retries:
            raise error
        
        # Apply error-specific corrections
        if isinstance(error, ValidationError):
            corrected_input = self._correct_validation_input(error, context)
            context['input'] = corrected_input
            context['current_retry'] = current_retry + 1
            
            # Re-execute with corrected input
            return context.get('retry_function')(context)
        
        raise error
    
    def _use_default_value(self, error: Exception, context: Dict[str, Any]) -> Any:
        """Return appropriate default value"""
        field_name = context.get('field_name')
        if field_name in self.default_values:
            return self.default_values[field_name]
        
        # Infer default based on error type
        if isinstance(error, ValidationError):
            error_info = error.errors()[0]
            error_type = error_info.get('type')
            
            if 'missing' in error_type:
                return None
            elif 'type_error' in error_type:
                expected_type = error_info.get('ctx', {}).get('expected_type', 'str')
                return self._get_type_default(expected_type)
        
        return None
    
    def _try_alternative_model(self, error: Exception, context: Dict[str, Any]) -> Any:
        """Try processing with alternative model"""
        current_model = context.get('model', 'unknown')
        
        for alt_model in self.alternative_models:
            if alt_model != current_model:
                try:
                    context['model'] = alt_model
                    context['use_alternative'] = True
                    return context.get('model_function')(context)
                except Exception:
                    continue
        
        raise error
    
    def _escalate_to_human(self, error: Exception, context: Dict[str, Any]) -> Any:
        """Escalate to human reviewer"""
        escalation_data = {
            'error': str(error),
            'context': context,
            'timestamp': datetime.utcnow().isoformat(),
            'severity': ErrorSeverity.HIGH.value,
            'requires_human_review': True
        }
        
        # Log escalation (implement your escalation mechanism here)
        logging.critical(f"Human escalation required: {escalation_data}")
        
        # Return safe placeholder while awaiting human review
        return {
            'status': 'pending_human_review',
            'message': 'This request requires human review due to safety concerns.',
            'escalation_id': str(uuid.uuid4())
        }
    
    def _fail_safe_response(self, error: Exception, context: Dict[str, Any]) -> Any:
        """Return fail-safe response"""
        return LLMResponse(
            content="I apologize, but I cannot process this request due to safety and security constraints.",
            confidence=0.0,
            safety_flags=SafetyFlags(prompt_injection=True),
            citations=[],
            metadata=ResponseMetadata(
                model='fail_safe',
                timestamp=datetime.utcnow()
            )
        )
    
    def _correct_validation_input(self, error: ValidationError, context: Dict[str, Any]) -> str:
        """Apply corrections to input based on validation errors"""
        input_text = context.get('input', '')
        
        for error_info in error.errors():
            error_type = error_info.get('type')
            
            if 'string_too_long' in error_type:
                max_length = error_info.get('ctx', {}).get('limit_value', 1000)
                input_text = input_text[:max_length]
            
            elif 'value_error.regex' in error_type:
                # Remove characters that don't match expected pattern
                pattern = error_info.get('ctx', {}).get('pattern', '')
                if pattern:
                    input_text = re.sub(f'[^{re.escape(pattern)}]', '', input_text)
        
        return input_text
    
    def _get_type_default(self, type_name: str) -> Any:
        """Get default value for a given type"""
        type_defaults = {
            'str': '',
            'int': 0,
            'float': 0.0,
            'bool': False,
            'list': [],
            'dict': {},
        }
        return type_defaults.get(type_name, None)

# Integration example with Instructor/LangChain
class SafeInstructorClient:
    def __init__(self, client, error_handler: GuardrailsErrorHandler):
        self.client = client
        self.error_handler = error_handler
        self.sanitizer = InputSanitizer()
        self.repairer = OutputRepairer()
    
    def create_with_validation(self, messages: List[Dict], response_model: BaseModel, 
                             max_retries: int = 3) -> Any:
        """Create response with comprehensive validation and error handling"""
        
        # Sanitize input messages
        sanitized_messages = []
        for msg in messages:
            cleaned_content, threats = self.sanitizer.sanitize_input(msg.get('content', ''))
            
            if any(threat['severity'] == 'CRITICAL' for threat in threats):
                raise ValueError("Critical security threats detected in input")
            
            sanitized_msg = msg.copy()
            sanitized_msg['content'] = cleaned_content
            sanitized_messages.append(sanitized_msg)
        
        # Attempt to get valid response
        for attempt in range(max_retries):
            try:
                response = self.client.chat.completions.create(
                    model="gpt-4",
                    response_model=response_model,
                    messages=sanitized_messages,
                    max_retries=0  # Handle retries ourselves
                )
                
                # Additional safety validation
                if hasattr(response, 'safety_flags') and response.safety_flags.has_critical_flags():
                    raise ValueError("Response contains critical safety flags")
                
                return response
                
            except ValidationError as e:
                # Try to repair the output
                if hasattr(self.client, '_last_raw_response'):
                    repaired = self.repairer.auto_repair(
                        self.client._last_raw_response,
                        response_model,
                        e
                    )
                    if repaired:
                        return response_model.parse_obj(repaired)
                
                # Use error handler for fallback
                context = {
                    'messages': sanitized_messages,
                    'response_model': response_model,
                    'attempt': attempt,
                    'max_retries': max_retries
                }
                
                severity = ErrorSeverity.HIGH if attempt == max_retries - 1 else ErrorSeverity.MEDIUM
                return self.error_handler.handle_error(e, context, severity)
            
            except Exception as e:
                context = {
                    'messages': sanitized_messages,
                    'response_model': response_model,
                    'attempt': attempt
                }
                
                severity = ErrorSeverity.CRITICAL if "security" in str(e).lower() else ErrorSeverity.HIGH
                return self.error_handler.handle_error(e, context, severity)
        
        # Final fallback
        return self.error_handler._fail_safe_response(
            Exception("Max retries exceeded"),
            {'messages': sanitized_messages}
        )
```

## 6. Integration Examples

### 6.1. FastAPI Integration

```python
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

app = FastAPI(title="Primarch Guardrails API")

# Initialize components
sanitizer = InputSanitizer()
error_handler = GuardrailsErrorHandler()
repairer = OutputRepairer()

@app.middleware("http")
async def validation_middleware(request: Request, call_next):
    """Apply validation to all incoming requests"""
    
    # Skip validation for health checks
    if request.url.path in ["/health", "/metrics"]:
        return await call_next(request)
    
    # Validate request size
    if hasattr(request, 'content_length') and request.content_length > 1024 * 1024:  # 1MB
        raise HTTPException(status_code=413, detail="Request too large")
    
    # Process request
    response = await call_next(request)
    return response

@app.post("/llm/completion", response_model=LLMResponse)
async def create_completion(request: Dict[str, Any]):
    """Create LLM completion with full validation"""
    
    try:
        # Validate and sanitize input
        prompt = request.get('prompt', '')
        cleaned_prompt, threats = sanitizer.sanitize_input(prompt)
        
        # Check for critical threats
        critical_threats = [t for t in threats if t['severity'] == 'CRITICAL']
        if critical_threats:
            raise HTTPException(
                status_code=400,
                detail=f"Security violation detected: {[t['type'] for t in critical_threats]}"
            )
        
        # Create completion with validation
        safe_client = SafeInstructorClient(client, error_handler)
        response = safe_client.create_with_validation(
            messages=[{"role": "user", "content": cleaned_prompt}],
            response_model=LLMResponse
        )
        
        return response
        
    except Exception as e:
        context = {'request': request}
        return error_handler.handle_error(e, context, ErrorSeverity.HIGH)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

This comprehensive validation system provides the robust foundation needed to meet the ≤1% structured output error rate acceptance gate while maintaining strict security and safety standards throughout the Primarch DW-05 system.
