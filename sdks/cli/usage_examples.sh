#!/bin/bash
# Primarch CLI - Usage Examples

echo "=== PRIMARCH CLI USAGE EXAMPLES ==="

# Basic authentication
echo "1. Setting up authentication..."
primarch auth set-key "${PRIMARCH_API_KEY}"
primarch auth whoami

# Configuration
echo "2. Configuring defaults..."
primarch config set model llama-3.1-8b-instruct
primarch config set persona frank
primarch config set max-tokens 1000
primarch config set safety-mode strict

# Basic completion
echo "3. Basic completion example..."
primarch complete "Explain the concept of machine learning in simple terms"

# File processing
echo "4. File processing example..."
echo "Artificial intelligence is rapidly transforming various industries..." > sample.txt
primarch complete --file sample.txt --output analysis.txt

# Interactive chat session
echo "5. Starting interactive chat..."
primarch chat --persona frank << EOF
Hello FRANK, I need help understanding neural networks
What are the main components of a neural network?
How do backpropagation algorithms work?
/save neural-networks-session
/exit
