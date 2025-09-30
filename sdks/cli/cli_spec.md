# Primarch CLI Specification

## Installation Options

### Package Managers
```bash
# Python pip
pip install primarch-cli

# Node.js npm
npm install -g @primarch/cli

# Homebrew (macOS/Linux)
brew install primarch/tap/primarch-cli

# Debian/Ubuntu
wget -qO- https://releases.primarch.ai/gpg | sudo apt-key add -
echo "deb https://releases.primarch.ai/apt stable main" | sudo tee /etc/apt/sources.list.d/primarch.list
sudo apt update && sudo apt install primarch-cli

# Red Hat/CentOS/Fedora
sudo rpm --import https://releases.primarch.ai/gpg
sudo yum-config-manager --add-repo https://releases.primarch.ai/rpm/primarch.repo
sudo yum install primarch-cli

# Arch Linux (AUR)
yay -S primarch-cli
```

### Binary Downloads
```bash
# Linux x64
curl -L https://releases.primarch.ai/cli/latest/primarch-linux-x64.tar.gz | tar xz
sudo mv primarch /usr/local/bin/

# macOS x64
curl -L https://releases.primarch.ai/cli/latest/primarch-darwin-x64.tar.gz | tar xz
sudo mv primarch /usr/local/bin/

# Windows x64
# Download from: https://releases.primarch.ai/cli/latest/primarch-windows-x64.zip
# Extract and add to PATH
```

## Authentication & Configuration

### Initial Setup
```bash
# Interactive authentication
primarch auth login
# Opens browser for OAuth flow
# Stores credentials in ~/.primarch/credentials

# API key authentication
primarch auth set-key pk_live_1234567890abcdef
# Stores encrypted key in ~/.primarch/credentials

# Environment variable
export PRIMARCH_API_KEY="pk_live_1234567890abcdef"

# Verify authentication
primarch auth whoami
# Output: Authenticated as: user@example.com (Plan: Pro)
```

### Configuration Management
```bash
# Set default configuration
primarch config set model llama-3.1-8b-instruct
primarch config set persona frank
primarch config set max-tokens 1000
primarch config set temperature 0.7
primarch config set safety-mode strict

# View current configuration
primarch config list
# Output:
# model: llama-3.1-8b-instruct
# persona: frank
# max-tokens: 1000
# temperature: 0.7
# safety-mode: strict

# Environment-specific configs
primarch config set --env production model llama-3.1-70b-instruct
primarch config set --env development model llama-3.1-8b-instruct

# Use specific environment
primarch --env production complete "Production query"
```

## Core Commands

### Completions
```bash
# Basic completion
primarch complete "Explain quantum computing"

# With parameters
primarch complete "Write a Python function" \
  --model llama-3.1-8b-instruct \
  --max-tokens 500 \
  --temperature 0.7 \
  --persona frank

# From file input
primarch complete --file prompt.txt

# To file output  
primarch complete "Explain AI" --output response.txt

# Stream to stdout
primarch complete "Tell a story" --stream

# JSON output format
primarch complete "Explain ML" --format json
# Output: {"response": "...", "usage": {"tokens": 150}, "model": "..."}
```

### Interactive Chat
```bash
# Start interactive session
primarch chat
> Hello FRANK, can you help me understand machine learning?
[AI response]
> What are neural networks?
[AI response]
> /save session-ml-basics
Session saved to ~/.primarch/sessions/session-ml-basics.json
> /exit

# Resume saved session
primarch chat --session session-ml-basics

# Chat with specific persona
primarch chat --persona frank

# Chat with system message
primarch chat --system "You are a helpful coding assistant"
```

### Tool Integration
```bash
# List available tools
primarch tools list
# Output:
# web_search: Search the web for current information
# code_interpreter: Execute Python code safely
# document_qa: Answer questions about uploaded documents
# calculator: Perform mathematical calculations

# Tool information
primarch tools info web_search
# Output: Tool capabilities, parameters, safety levels

# Invoke tools
primarch tools web-search "latest AI research 2025"
primarch tools code-interpreter --file script.py
primarch tools calculator "sqrt(144) + 5^2"

# Document Q&A
primarch tools document-qa \
  --file research-paper.pdf \
  --query "What is the main conclusion?"
```

### File Processing
```bash
# Process single file
primarch process --input document.txt --prompt "Summarize this text"

# Batch processing
primarch batch \
  --input-dir ./documents \
  --output-dir ./summaries \
  --prompt "Create a 3-sentence summary of this document"

# Template processing
primarch template \
  --template prompt-template.j2 \
  --vars vars.json \
  --output rendered-prompt.txt

# Pipeline processing
cat input.txt | primarch complete | primarch summarize --length short
```

### Conversation Management
```bash
# Create conversation
primarch conversation create \
  --name "research-session" \
  --persona frank

# List conversations
primarch conversation list
# Output:
# ID: conv_123 | Name: research-session | Messages: 5 | Updated: 2025-09-26
# ID: conv_456 | Name: coding-help | Messages: 12 | Updated: 2025-09-25

# Add message to conversation
primarch conversation add \
  --id conv_123 \
  --message "What are the latest developments in AI safety?"

# Continue conversation
primarch conversation complete --id conv_123

# Export conversation
primarch conversation export \
  --id conv_123 \
  --format jsonl \
  --output conversation-export.jsonl

# Import conversation
primarch conversation import --file backup-conversations.jsonl
```

## Advanced Features

### Embeddings
```bash
# Generate embeddings for text
primarch embeddings "Text to embed" --model text-embedding-3-small

# Batch embeddings from file
primarch embeddings --file texts.txt --output embeddings.json

# Similarity search
primarch embeddings search \
  --index vector-index \
  --query "machine learning" \
  --top-k 5
```

### Safety & Monitoring
```bash
# Safety test prompts
primarch safety-test --file test-prompts.txt
# Output: Tests passed: 45/45 | Blocks: 5 | Warnings: 2

# Usage monitoring
primarch usage
# Output:
# Current period: September 2025
# Tokens used: 125,430 / 1,000,000 (12.5%)
# Requests: 2,834 / 10,000 (28.3%)
# Cost: $23.45 / $100.00 (23.5%)

# Detailed usage breakdown
primarch usage --detailed --month 2025-09
# Output by model, tool, date breakdown

# Billing information
primarch billing
# Output:
# Plan: Professional ($49/month)
# Next billing: 2025-10-15
# Payment method: •••• 4242
# Invoices: https://billing.primarch.ai/invoices
```

### Tracing & Debugging
```bash
# Enable request tracing
primarch complete "Debug this request" \
  --trace \
  --trace-id custom-trace-123

# View trace details
primarch trace show custom-trace-123
# Output: Detailed trace information including latency, model calls, tool usage

# Debug mode with verbose output
primarch complete "Test prompt" --debug --verbose
# Output: Full request/response headers, timing, model selection logic
```

### Export & Import
```bash
# Export all data
primarch export \
  --format jsonl \
  --include conversations,usage,settings \
  --output primarch-backup.jsonl \
  --encrypt

# Import data
primarch import \
  --file primarch-backup.jsonl \
  --decrypt \
  --merge

# Selective export
primarch export \
  --conversations \
  --from 2025-09-01 \
  --to 2025-09-30 \
  --output september-conversations.json
```

## Configuration Files

### Global Config (~/.primarch/config.yaml)
```yaml
# Default settings
defaults:
  model: "llama-3.1-8b-instruct"
  persona: "frank"
  max_tokens: 1000
  temperature: 0.7
  safety_mode: "strict"

# Authentication
auth:
  method: "api_key"  # or "oauth"
  api_key_path: "~/.primarch/credentials"

# Environment-specific overrides
environments:
  production:
    model: "llama-3.1-70b-instruct"
    safety_mode: "strict"
    max_tokens: 2000
  
  development:
    model: "llama-3.1-8b-instruct"
    safety_mode: "moderate"
    debug: true

# Output preferences
output:
  format: "text"  # text, json, yaml
  colors: true
  timestamps: false
  verbose: false

# Tool preferences
tools:
  web_search:
    max_results: 10
    safe_search: true
  code_interpreter:
    timeout: 30
    memory_limit: "512MB"
```

### Project Config (./primarch.yaml)
```yaml
# Project-specific settings
project:
  name: "my-ai-project"
  version: "1.0.0"

# Model preferences for this project
model_config:
  default: "llama-3.1-8b-instruct"
  fallback: "llama-3.1-7b-instruct"
  
# Custom prompts
prompts:
  summarize: "Create a concise summary of the following text:\n\n{text}"
  analyze: "Analyze the following data and provide insights:\n\n{data}"

# Tool configurations
tools:
  enabled: ["web_search", "code_interpreter"]
  web_search:
    default_query_prefix: "site:arxiv.org OR site:github.com"

# Safety settings
safety:
  mode: "strict"
  content_filters: ["pii", "toxicity", "violence"]
  custom_blocks: ["internal-docs", "proprietary-code"]
```

## Exit Codes

```bash
# Success
0   # Command completed successfully

# Client errors (1-99)
1   # General error
2   # Authentication failed
3   # Invalid arguments
4   # Configuration error
5   # File not found
6   # Permission denied
7   # Network error
8   # Timeout

# API errors (100-199)  
100 # API server error
101 # Rate limit exceeded
102 # Quota exceeded
103 # Invalid request
104 # Content policy violation
105 # Model unavailable
106 # Tool invocation failed

# Safety errors (200-299)
200 # Safety filter triggered
201 # PII detected
202 # Toxicity detected
203 # Prompt injection detected
204 # Unauthorized tool access
```

## Environment Variables

```bash
# Authentication
PRIMARCH_API_KEY="pk_live_..."           # API key
PRIMARCH_AUTH_METHOD="api_key"           # oauth or api_key

# Configuration
PRIMARCH_MODEL="llama-3.1-8b-instruct"   # Default model
PRIMARCH_PERSONA="frank"                 # Default persona
PRIMARCH_MAX_TOKENS="1000"               # Default token limit
PRIMARCH_TEMPERATURE="0.7"               # Default temperature
PRIMARCH_SAFETY_MODE="strict"            # Safety level

# Endpoints
PRIMARCH_BASE_URL="https://api.primarch.ai/v1"  # API base URL
PRIMARCH_WS_URL="wss://ws.primarch.ai/v1"       # WebSocket URL

# Output
PRIMARCH_OUTPUT_FORMAT="text"            # text, json, yaml
PRIMARCH_NO_COLOR="false"                # Disable colors
PRIMARCH_VERBOSE="false"                 # Verbose output
PRIMARCH_DEBUG="false"                   # Debug mode

# Behavior
PRIMARCH_TIMEOUT="30"                    # Request timeout (seconds)
PRIMARCH_RETRIES="3"                     # Max retry attempts
PRIMARCH_CONFIG_DIR="~/.primarch"        # Config directory
PRIMARCH_CACHE_DIR="~/.primarch/cache"   # Cache directory
```

## Shell Integration

### Bash Completion
```bash
# Install completion
primarch completion bash > /etc/bash_completion.d/primarch

# Or add to ~/.bashrc
eval "$(primarch completion bash)"
```

### Zsh Completion
```bash
# Install completion
primarch completion zsh > /usr/local/share/zsh/site-functions/_primarch

# Or add to ~/.zshrc
eval "$(primarch completion zsh)"
```

### Fish Completion
```bash
# Install completion
primarch completion fish > ~/.config/fish/completions/primarch.fish
```

### Aliases & Functions
```bash
# Useful aliases
alias pai="primarch complete"
alias pchat="primarch chat"
alias ptools="primarch tools"
alias pusage="primarch usage"

# Wrapper function for quick completions
ask() {
  primarch complete "$*" --stream
}

# Quick file summarization
summarize() {
  primarch process --input "$1" --prompt "Summarize this document in 3 paragraphs"
}
```

## Platform-Specific Features

### macOS Integration
```bash
# Spotlight integration
primarch index --spotlight

# Services menu integration
primarch install-services

# Notification Center
primarch complete "Long task" --notify-on-complete
```

### Windows Integration
```bash
# PowerShell completion
primarch completion powershell | Out-String | iex

# Context menu integration
primarch install-context-menu

# Windows notifications
primarch complete "Long task" --notify-on-complete
```

### Linux Integration
```bash
# Desktop file
primarch install-desktop-file

# systemd user service for background tasks
primarch service install --user

# DBus integration
primarch complete "Query" --dbus-notify
```
