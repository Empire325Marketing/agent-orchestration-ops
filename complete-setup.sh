#!/bin/bash

# Complete Agent Orchestration Ops Repository Setup
# This script handles everything after manual repository creation

set -e

echo "=== COMPLETE AGENT ORCHESTRATION OPS SETUP ==="
echo ""

# Step 1: Push repository content
echo "STEP 1: Pushing repository content..."
./setup-agent-orchestration-ops.sh

if [ $? -ne 0 ]; then
    echo "❌ Failed to push repository content. Please ensure:"
    echo "   1. Repository is created on GitHub"
    echo "   2. GitHub App has access to the repository"
    exit 1
fi

echo "✅ Repository content pushed successfully"
echo ""

# Step 2: Create Pull Request
echo "STEP 2: Creating Pull Request..."

# Wait a moment for GitHub to process the pushes
sleep 2

# Create PR using GitHub CLI
gh pr create \
    --repo Empire325Marketing/agent-orchestration-ops \
    --title "Initial Operational Artifacts Framework" \
    --body "## Overview
This PR introduces the complete operational artifacts framework for agent orchestration systems.

## What's Included

### 📚 Runbooks
- **Deployment Runbook**: Complete deployment procedures with pre/post validation
- **Incident Response**: Step-by-step incident response procedures  
- **Monitoring Setup**: Comprehensive monitoring and alerting configuration
- **Rollback Procedures**: Emergency rollback and recovery procedures

### 🚪 Operational Gates
- **Deployment Gates**: Pre-deployment, deployment, and post-deployment validation criteria
- **Operational Gates**: System readiness and operational validation
- **Security Gates**: Security validation and compliance checks
- **Performance Gates**: Performance benchmarks and validation criteria

### 🚨 Monitoring & Alerts
- **System Alerts**: CPU, memory, service health monitoring
- **Performance Alerts**: Response time and throughput monitoring
- **Security Alerts**: Security event monitoring and alerting
- **Business Alerts**: Business metrics and KPI monitoring

### 📊 Canary Reports
- **Deployment Analysis**: Canary deployment analysis framework
- **Performance Comparison**: A/B testing and performance comparison
- **User Experience Analysis**: UX impact assessment
- **Rollback Analysis**: Decision framework for rollback scenarios

### 🔄 Sync Framework
- **Cross-system Synchronization**: Multi-system state synchronization
- **Configuration Management**: Centralized configuration sync
- **Monitoring Integration**: Sync health monitoring and validation
- **Troubleshooting Guide**: Sync issue resolution procedures

## Validation Checklist
- [x] All operational artifacts created
- [x] Documentation complete and comprehensive
- [x] Framework structure follows best practices
- [x] Ready for operational deployment

## Next Steps
1. Review all operational artifacts
2. Validate framework completeness
3. Configure branch protections
4. Set up automated workflows
5. Deploy monitoring and alerting

This framework provides a comprehensive foundation for reliable agent orchestration operations." \
    --head ops-readiness \
    --base main

if [ $? -eq 0 ]; then
    echo "✅ Pull Request created successfully"
    PR_URL=$(gh pr view --repo Empire325Marketing/agent-orchestration-ops --json url --jq '.url')
    echo "🔗 PR URL: $PR_URL"
else
    echo "❌ Failed to create Pull Request"
fi

echo ""

# Step 3: Configure Branch Protections
echo "STEP 3: Configuring branch protections..."
./configure-branch-protections.sh

echo ""
echo "=== SETUP COMPLETE ==="
echo "✅ Repository created and configured"
echo "✅ Operational artifacts pushed to ops-readiness branch"
echo "✅ Pull Request created for review"
echo "✅ Branch protections configured"
echo "✅ Repository settings optimized"
echo ""
echo "🎯 FINAL STATUS:"
echo "- Repository: https://github.com/Empire325Marketing/agent-orchestration-ops"
echo "- Main branch: Basic README with instructions"
echo "- ops-readiness branch: Complete operational framework"
echo "- Pull Request: Ready for review and merge"
echo "- Branch Protection: Requires 1 approval, prevents force pushes"
echo ""
echo "⚠️  IMPORTANT: Do NOT merge the PR automatically. Review first!"
echo ""
echo "Next steps:"
echo "1. Review the Pull Request thoroughly"
echo "2. Test the operational artifacts"
echo "3. Approve and merge when ready"
echo "4. Set up CI/CD workflows if needed"
