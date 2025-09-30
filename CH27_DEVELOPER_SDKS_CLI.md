# Chapter 27 — Developer SDKs & CLI

## Overview
Python SDK, JavaScript SDK, and CLI for Primarch AI Platform integration with comprehensive examples, safety guardrails, and release policies.

## Python SDK (primarch-py)

### Installation & Authentication
```python
pip install primarch-py

# Authentication
from primarch import PrimarchClient

# API key authentication
client = PrimarchClient(api_key="pk_live_...")

# OAuth2 authentication  
client = PrimarchClient(
    oauth_client_id="client_123",
    oauth_client_secret="secret_456"
)

# Environment-based auth
client = PrimarchClient()  # Uses PRIMARCH_API_KEY env var
```

### Core API Methods
```python
# Completions
response = client.completions.create(
    prompt="Explain quantum computing",
    model="llama-3.1-8b-instruct",
    max_tokens=500,
    temperature=0.7,
    persona="frank"  # Optional persona override
)

# Embeddings
embeddings = client.embeddings.create(
    input=["text to embed", "another text"],
    model="text-embedding-3-small"
)

# Tool calls
result = client.tools.invoke(
    tool_name="web_search",
    parameters={"query": "latest AI research"},
    safety_mode="strict"  # strict|moderate|permissive
)

# Conversation management
conversation = client.conversations.create()
conversation.add_message("user", "Hello FRANK")
response = conversation.complete()
```

### Streaming Support
```python
# Streaming completions
stream = client.completions.create_stream(
    prompt="Write a story about AI",
    model="llama-3.1-8b-instruct"
)

for chunk in stream:
    if chunk.delta.content:
        print(chunk.delta.content, end="")
```

### Safety & Observability
```python
# Safety configuration
client.configure_safety(
    pii_detection=True,
    toxicity_threshold=0.1,
    prompt_injection_detection=True
)

# Request tracing
with client.trace_request(span_name="user_query") as span:
    response = client.completions.create(
        prompt="Explain machine learning",
        trace_id=span.trace_id
    )
```

## JavaScript SDK (primarch-js)

### Installation & Setup
```bash
npm install @primarch/sdk
# or
yarn add @primarch/sdk
```

```javascript
import { PrimarchClient } from '@primarch/sdk';

// Initialize client
const client = new PrimarchClient({
  apiKey: 'pk_live_...',
  baseURL: 'https://api.primarch.ai/v1',
  timeout: 30000
});

// Environment-based configuration
const client = new PrimarchClient(); // Uses PRIMARCH_API_KEY
```

### Core API Usage
```javascript
// Completions
const response = await client.completions.create({
  prompt: "Explain blockchain technology",
  model: "llama-3.1-8b-instruct",
  maxTokens: 500,
  temperature: 0.7,
  persona: "frank"
});

// Embeddings
const embeddings = await client.embeddings.create({
  input: ["text to embed", "another text"],
  model: "text-embedding-3-small"
});

// Tool invocation
const result = await client.tools.invoke({
  toolName: "code_interpreter",
  parameters: { code: "print('Hello World')" },
  safetyMode: "strict"
});

// Conversation handling
const conversation = await client.conversations.create();
await conversation.addMessage("user", "Hello FRANK");
const response = await conversation.complete();
```

### Streaming & Real-time
```javascript
// Streaming responses
const stream = await client.completions.createStream({
  prompt: "Generate a poem about technology",
  model: "llama-3.1-8b-instruct"
});

for await (const chunk of stream) {
  if (chunk.delta?.content) {
    process.stdout.write(chunk.delta.content);
  }
}

// WebSocket real-time
const ws = client.realtime.connect();
ws.on('message', (response) => {
  console.log('AI Response:', response.content);
});
ws.send({ type: 'completion', prompt: 'Hello' });
```

### Error Handling & Retry
```javascript
try {
  const response = await client.completions.create({
    prompt: "Explain AI safety",
    model: "llama-3.1-8b-instruct"
  });
} catch (error) {
  if (error instanceof PrimarchAPIError) {
    console.error('API Error:', error.message, error.code);
  } else if (error instanceof PrimarchNetworkError) {
    console.error('Network Error:', error.message);
  } else {
    console.error('Unexpected Error:', error);
  }
}

// Automatic retry configuration
const client = new PrimarchClient({
  apiKey: 'pk_live_...',
  retry: {
    attempts: 3,
    backoff: 'exponential',
    jitter: true
  }
});
```

## CLI Tool (primarch-cli)

### Installation
```bash
# Via pip
pip install primarch-cli

# Via npm
npm install -g @primarch/cli

# Via homebrew
brew install primarch/tap/primarch-cli

# Verify installation
primarch --version
```

### Authentication & Configuration
```bash
# Configure API key
primarch auth login
# or
primarch auth set-key pk_live_...

# Environment-based
export PRIMARCH_API_KEY="pk_live_..."

# Configure default settings
primarch config set model llama-3.1-8b-instruct
primarch config set persona frank
primarch config set max-tokens 1000
```

### Basic Commands
```bash
# Quick completion
primarch complete "Explain quantum computing"

# With specific model and parameters
primarch complete "Write a Python function" \
  --model llama-3.1-8b-instruct \
  --max-tokens 500 \
  --temperature 0.7

# Interactive mode
primarch chat
> Hello FRANK
> [AI response]
> exit

# File processing
primarch complete --file input.txt --output response.txt

# Batch processing
primarch batch --input-dir ./prompts --output-dir ./responses
```

### Tool Integration
```bash
# Invoke tools
primarch tools web-search "latest AI research"
primarch tools code-interpreter --file script.py
primarch tools document-qa --file document.pdf --query "What is the main conclusion?"

# List available tools
primarch tools list

# Tool capability check
primarch tools info web-search
```

### Safety & Monitoring
```bash
# Safety-first mode
primarch complete "Explain cryptocurrency" --safety strict

# Monitor usage
primarch usage --month 2025-09
primarch billing --current-period

# Trace requests
primarch complete "Hello" --trace --trace-id req_123

# Validate safety
primarch safety-test --file test-prompts.txt
```

### Advanced Features
```bash
# Pipeline processing
echo "Explain AI" | primarch complete | primarch summarize

# Template processing
primarch template render --template prompt.j2 --vars vars.json

# Conversation management
primarch conversation create --name "research-session"
primarch conversation add --id conv_123 --message "Hello FRANK"
primarch conversation complete --id conv_123

# Export/import
primarch export --format jsonl --output data.jsonl
primarch import --file conversations.jsonl
```

## Safety Integration

### Default Safety Policies
```yaml
# Applied to all SDK calls
safety_defaults:
  pii_detection: true
  toxicity_filtering: true
  prompt_injection_protection: true
  content_policy_enforcement: true
  rate_limiting: true
  audit_logging: true
```

### Customizable Safety Modes
```python
# Python SDK
client.configure_safety_mode("strict")  # Maximum protection
client.configure_safety_mode("moderate")  # Balanced
client.configure_safety_mode("permissive")  # Minimal filtering

# JavaScript SDK  
const client = new PrimarchClient({
  safetyMode: "strict",
  customSafetyRules: {
    blockPII: true,
    toxicityThreshold: 0.1
  }
});

# CLI
primarch config set safety-mode strict
```

## Cost Management

### Usage Tracking
```python
# Python SDK
usage = client.usage.get_current_period()
print(f"Tokens used: {usage.tokens_used}/{usage.tokens_limit}")
print(f"Cost: ${usage.cost:.2f}")

# Set spending limits
client.billing.set_limit(monthly_limit=100.00)
```

```javascript
// JavaScript SDK
const usage = await client.usage.getCurrentPeriod();
console.log(`Tokens: ${usage.tokensUsed}/${usage.tokensLimit}`);
console.log(`Cost: $${usage.cost.toFixed(2)}`);
```

```bash
# CLI
primarch usage --current
primarch billing set-limit --monthly 100.00
primarch billing alerts enable --threshold 80
```

## Release Policies & Versioning

### Semantic Versioning
- **Major (X.0.0)**: Breaking API changes
- **Minor (X.Y.0)**: New features, backward compatible
- **Patch (X.Y.Z)**: Bug fixes, security updates

### Release Channels
```bash
# Stable (default)
pip install primarch-py
npm install @primarch/sdk

# Beta releases
pip install primarch-py --pre
npm install @primarch/sdk@beta

# Nightly builds
pip install primarch-py --index-url https://nightly.primarch.ai/pypi/
npm install @primarch/sdk@nightly
```

### Compatibility Matrix
| SDK Version | API Version | Python | Node.js |
|-------------|-------------|---------|---------|
| 1.0.x       | v1         | ≥3.8    | ≥16     |
| 1.1.x       | v1         | ≥3.8    | ≥16     |
| 2.0.x       | v2         | ≥3.9    | ≥18     |

### Deprecation Policy
- **Notice**: 6 months advance warning
- **Support**: 12 months continued support
- **Migration**: Automated migration tools provided

## Testing & Quality

### SDK Test Coverage
```bash
# Python SDK tests
pytest tests/ --cov=primarch --cov-report=html

# JavaScript SDK tests  
npm test
npm run test:coverage

# CLI tests
pytest cli_tests/ --integration
```

### Integration Testing
```python
# Example integration test
def test_end_to_end_completion():
    client = PrimarchClient(api_key=test_api_key)
    response = client.completions.create(
        prompt="Test prompt",
        model="llama-3.1-8b-instruct"
    )
    assert response.choices[0].message.content
    assert response.usage.total_tokens > 0
```

### Performance Benchmarks
- **Cold start latency**: <500ms
- **Streaming first token**: <200ms  
- **Throughput**: 1000+ req/min per client
- **Memory usage**: <50MB base overhead

## Cross-References
- Authentication: Chapter 8 (Secrets & IAM)
- Safety Integration: Chapter 17 (Safety Red-Teaming)
- Cost Management: Chapter 24 (Billing & Usage)
- Observability: Chapter 7 (OTel Integration)
- Tool Registry: Chapter 5 (Tool & API Registry)
